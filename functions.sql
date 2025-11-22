/*
Сценарий: менти вводит email, выбирает навык и цель. 
Функция:
- находит mentee_id по email,
- находит skill_id по названию,
- создаёт mentorship_requests,
- возвращает id созданного запроса,
- перехватывает типовые ошибки и выдаёт понятные сообщения.
*/
CREATE OR REPLACE FUNCTION fn_create_request(
    p_mentee_email TEXT,
    p_skill_name   TEXT,
    p_goal         TEXT,
    p_desired_prof SMALLINT DEFAULT NULL
) RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_mentee_id BIGINT;
    v_skill_id  BIGINT;
    v_req_id    BIGINT;
BEGIN
    SELECT id INTO v_mentee_id
    FROM users
    WHERE email = p_mentee_email AND is_mentee = TRUE;

    IF v_mentee_id IS NULL THEN
        RAISE EXCEPTION 'Менти с email=% не найден или не имеет роли mentee', p_mentee_email;
    END IF;

    SELECT id INTO v_skill_id
    FROM skills
    WHERE name = p_skill_name;

    IF v_skill_id IS NULL THEN
        RAISE EXCEPTION 'Навык "%" отсутствует в справочнике', p_skill_name;
    END IF;

    INSERT INTO mentorship_requests(mentee_id, skill_id, goal, desired_proficiency, status)
    VALUES (v_mentee_id, v_skill_id, p_goal, p_desired_prof, 'open')
    RETURNING id INTO v_req_id;

    RETURN v_req_id;

EXCEPTION
    WHEN check_violation THEN
        RAISE EXCEPTION 'Некорректные данные запроса (проверьте уровень/статус/цель)';
    WHEN others THEN
        RAISE EXCEPTION 'Ошибка при создании запроса: %', SQLERRM;
END;
$$;

/*
Сценарий: менти (или система) принимает отклик ментора.
Процедура:
- делает заявку accepted,
- переводит запрос в matched,
- создаёт mentorship_matches, если пары ещё нет.
Ошибки unique/foreign key преобразуются в бизнес-сообщения.
*/
CREATE OR REPLACE PROCEDURE sp_accept_application(
    p_application_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_request_id BIGINT;
    v_mentor_id  BIGINT;
    v_mentee_id  BIGINT;
    v_skill_id   BIGINT;
BEGIN
    SELECT a.request_id, a.mentor_id, r.mentee_id, r.skill_id
    INTO v_request_id, v_mentor_id, v_mentee_id, v_skill_id
    FROM mentorship_applications a
    JOIN mentorship_requests r ON r.id = a.request_id
    WHERE a.id = p_application_id;

    IF v_request_id IS NULL THEN
        RAISE EXCEPTION 'Заявка id=% не найдена', p_application_id;
    END IF;

    UPDATE mentorship_applications
    SET status = 'accepted', updated_at = now()
    WHERE id = p_application_id;

    UPDATE mentorship_requests
    SET status = 'matched', updated_at = now()
    WHERE id = v_request_id;

    -- создаём пару только если такой ещё нет
    IF NOT EXISTS (
        SELECT 1 FROM mentorship_matches m
        WHERE m.mentor_id = v_mentor_id
          AND m.mentee_id = v_mentee_id
          AND m.skill_id  = v_skill_id
    ) THEN
        INSERT INTO mentorship_matches(
            mentor_id, mentee_id, skill_id, request_id,
            status, started_at
        ) VALUES (
            v_mentor_id, v_mentee_id, v_skill_id, v_request_id,
            'active', now()
        );
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Такая пара по этому навыку уже существует';
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Нарушение ссылочной целостности (не найден пользователь/навык/запрос)';
    WHEN others THEN
        RAISE EXCEPTION 'Ошибка при принятии заявки: %', SQLERRM;
END;
$$;

/*
Сценарий: показать качество ментора в профиле.
Функция возвращает средний рейтинг по всем оценённым сессиям ментора.
*/
CREATE OR REPLACE FUNCTION fn_mentor_avg_rating(
    p_mentor_id BIGINT
) RETURNS NUMERIC(3,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_avg NUMERIC(3,2);
BEGIN
    SELECT CAST(AVG(sr.rating) AS numeric(3,2))
    INTO v_avg
    FROM mentorship_matches m
    JOIN sessions se ON se.match_id = m.id
    JOIN session_ratings sr ON sr.session_id = se.id
    WHERE m.mentor_id = p_mentor_id;

    RETURN v_avg; -- может быть NULL, если оценок нет
END;
$$;

-- новый запрос
SELECT fn_create_request(
    'olga.ivanova@mail.com',
    'Career',
    'Хочу подготовиться к интервью на стажировку'
) AS new_request_id;

-- принять заявку
CALL sp_accept_application(1);

-- посчитать средний рейтинг ментора
SELECT fn_mentor_avg_rating(6) AS mentor6_avg_rating;

SELECT fn_create_request(
    'olga.ivanova@mail.com',
    'Wrong skill',
    'Хочу подготовиться к интервью на стажировку'
) AS new_request_id;

CALL sp_accept_application(99999);

SELECT fn_mentor_avg_rating(9999) AS mentor6_avg_rating;
