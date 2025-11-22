/* 
Назначение: витрина активных пар для view “текущее менторство”.
Что показывает: для каждой активной пары — кто ментор и ученик, по какому навыку они работают, когда началось менторство, сколько завершённых сессий уже проведено, когда была последняя завершённая встреча и как в среднем оценивают работу пары. 
*/
CREATE VIEW view_active_matches_progress AS
SELECT
    m.id AS match_id,
    mentor.id AS mentor_id,
    mentor.full_name AS mentor_name,
    mentee.id AS mentee_id,
    mentee.full_name AS mentee_name,
    s.id AS skill_id,
    s.name AS skill_name,
    m.started_at,
    COUNT(se.id) FILTER (WHERE se.status = 'completed') AS completed_sessions,
    MAX(se.scheduled_at) FILTER (WHERE se.status = 'completed') AS last_completed_session_at,
    AVG(sr.rating)::numeric(3,2) AS avg_session_rating
FROM mentorship_matches m
JOIN users mentor ON mentor.id = m.mentor_id
JOIN users mentee ON mentee.id = m.mentee_id
JOIN skills s ON s.id = m.skill_id
LEFT JOIN sessions se ON se.match_id = m.id
LEFT JOIN session_ratings sr ON sr.session_id = se.id
WHERE m.status = 'active'
GROUP BY
    m.id, mentor.id, mentor.full_name,
    mentee.id, mentee.full_name,
    s.id, s.name, m.started_at;


/* 
Назначение: статистика по менторам для рейтинга и карточки наставника.
Что показывает: по каждому пользователю-ментору — сколько у него активных пар, сколько завершённых сессий он провёл, какая у него средняя оценка по встречам, и когда была последняя завершённая сессия.
*/
CREATE VIEW view_mentor_stats AS
SELECT
    u.id AS mentor_id,
    u.full_name AS mentor_name,
    COUNT(DISTINCT m.id) FILTER (WHERE m.status = 'active') AS active_matches,
    COUNT(se.id) FILTER (WHERE se.status = 'completed') AS completed_sessions,
    AVG(sr.rating)::numeric(3,2) AS avg_rating,
    MAX(se.scheduled_at) FILTER (WHERE se.status = 'completed') AS last_session_at
FROM users u
LEFT JOIN mentorship_matches m ON m.mentor_id = u.id
LEFT JOIN sessions se ON se.match_id = m.id
LEFT JOIN session_ratings sr ON sr.session_id = se.id
WHERE u.is_mentor = TRUE
GROUP BY u.id, u.full_name;


/* 
Назначение: сводка “рынка навыков” для продуктовой аналитики (спрос/предложение).
Что показывает: по каждому навыку — сколько открытых запросов от менти (спрос), сколько менторов указали этот навык (предложение), сколько среди них сильных (уровень ≥ 7), и каков средний уровень владения навыком у менторов.
*/
CREATE VIEW view_skill_market_summary AS
SELECT
    s.id AS skill_id,
    s.name AS skill_name,
    COUNT(DISTINCT CASE WHEN r.status = 'open' THEN r.id END) AS open_requests,
    COUNT(DISTINCT CASE WHEN u.is_mentor = TRUE THEN us.user_id END) AS mentors_with_skill,
    COUNT(DISTINCT CASE 
        WHEN u.is_mentor = TRUE AND us.proficiency >= 7 THEN us.user_id 
    END) AS strong_mentors,

    CAST(AVG(CASE WHEN u.is_mentor = TRUE THEN us.proficiency END) AS numeric(4,2)) AS avg_mentor_proficiency
FROM skills s
LEFT JOIN mentorship_requests r ON r.skill_id = s.id
LEFT JOIN user_skills us ON us.skill_id = s.id
LEFT JOIN users u ON u.id = us.user_id
GROUP BY s.id, s.name;

-- активные пары + прогресс/оценки
SELECT *
FROM view_active_matches_progress
ORDER BY started_at DESC
LIMIT 20;


-- все менторы и их статистика
SELECT *
FROM view_mentor_stats
ORDER BY avg_rating DESC NULLS LAST, completed_sessions DESC
LIMIT 20;


-- сводка по каждому навыку
SELECT *
FROM view_skill_market_summary
ORDER BY open_requests DESC, strong_mentors ASC
LIMIT 50;
