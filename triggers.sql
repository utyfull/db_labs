/* 
Сценарий: перед вставкой в session_ratings проверяем, что оценку ставит участник пары
(то есть rater_id совпадает с mentor_id или mentee_id для сессии).
Если нет — блокируем операцию.
*/

CREATE OR REPLACE FUNCTION trg_check_rater_is_participant()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_mentor_id BIGINT;
    v_mentee_id BIGINT;
BEGIN
    SELECT m.mentor_id, m.mentee_id
    INTO v_mentor_id, v_mentee_id
    FROM sessions se
    JOIN mentorship_matches m ON m.id = se.match_id
    WHERE se.id = NEW.session_id;

    IF NEW.rater_id <> v_mentor_id AND NEW.rater_id <> v_mentee_id THEN
        RAISE EXCEPTION 'Оценку может оставить только участник данной пары';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER before_rating_check
BEFORE INSERT ON session_ratings
FOR EACH ROW
EXECUTE FUNCTION trg_check_rater_is_participant();



/* 
Сценарий: создаём матч по request_id → сразу переводим запрос в matched.
*/

CREATE OR REPLACE FUNCTION public.trg_match_sets_request_matched()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- если request_id указан, но такого запроса нет
  IF NEW.request_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.mentorship_requests r WHERE r.id = NEW.request_id
  ) THEN
    RAISE EXCEPTION 'Нельзя создать матч: запрос id=% не найден', NEW.request_id;
  END IF;

  -- если такая пара по этому навыку уже есть
  IF EXISTS (
    SELECT 1 FROM public.mentorship_matches m
    WHERE m.mentor_id = NEW.mentor_id
      AND m.mentee_id = NEW.mentee_id
      AND m.skill_id  = NEW.skill_id
  ) THEN
    RAISE EXCEPTION 'Нельзя создать матч: такая пара по этому навыку уже существует';
  END IF;

  IF NEW.request_id IS NOT NULL THEN
    UPDATE public.mentorship_requests
    SET status='matched', updated_at=now()
    WHERE id = NEW.request_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER before_match_sets_request_matched
BEFORE INSERT ON public.mentorship_matches
FOR EACH ROW
EXECUTE FUNCTION public.trg_match_sets_request_matched();

-- test 1
INSERT INTO session_ratings(session_id, rater_id, rating, comment)
VALUES (
  (SELECT id FROM sessions ORDER BY id LIMIT 1),
  (SELECT id FROM users
   WHERE id NOT IN (
     SELECT m.mentor_id
     FROM mentorship_matches m
     JOIN sessions se ON se.match_id = m.id
     WHERE se.id = (SELECT id FROM sessions ORDER BY id LIMIT 1)
     UNION
     SELECT m.mentee_id
     FROM mentorship_matches m
     JOIN sessions se ON se.match_id = m.id
     WHERE se.id = (SELECT id FROM sessions ORDER BY id LIMIT 1)
   )
   ORDER BY id LIMIT 1),
  5,
  'Тест чужой оценки'
);

-- test 2
INSERT INTO public.mentorship_matches(mentor_id, mentee_id, skill_id, request_id, status, started_at)
SELECT mentor_id, mentee_id, skill_id, request_id, 'active', now()
FROM public.mentorship_matches
LIMIT 1;
