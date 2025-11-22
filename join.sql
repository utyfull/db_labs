-- хотим получить список всех текущих (активных) связок «ментор–ученик» на платформе: кто выступает ментором, кто является учеником, по какому навыку они работают, когда эта работа началась.
SELECT
    m.id AS match_id,
    mentor.full_name AS mentor_name,
    mentee.full_name AS mentee_name,
    s.name AS skill,
    m.started_at
FROM mentorship_matches m
INNER JOIN users mentor ON mentor.id = m.mentor_id
INNER JOIN users mentee ON mentee.id = m.mentee_id
INNER JOIN skills s ON s.id = m.skill_id
WHERE m.status = 'active'
ORDER BY m.started_at DESC;
 
-- берём все открытые запросы на менторство, созданные учениками, и для каждого запроса хотим понять: кто его создал (какой ученик), по какому навыку, с какой целью, сколько менторов уже откликнулось.
SELECT
    r.id AS request_id,
    u.full_name AS mentee_name,
    s.name AS skill,
    r.goal,
    r.created_at,
    COUNT(a.id) AS applications_count
FROM mentorship_requests r
INNER JOIN users u ON u.id = r.mentee_id
INNER JOIN skills s ON s.id = r.skill_id
LEFT JOIN mentorship_applications a ON a.request_id = r.id
WHERE r.status = 'open'
GROUP BY r.id, u.full_name, s.name, r.goal, r.created_at
ORDER BY applications_count DESC, r.created_at DESC;

-- хотим построить ленту всех сессий определённого менти, и для каждой сессии показать: дату/время и статус (была/будет/отменена), с каким ментором она проходила, по какому навыку, есть ли оценка и какая она.
SELECT
    se.id AS session_id,
    se.scheduled_at,
    se.status,
    mentor.full_name AS mentor_name,
    sk.name AS skill,
    sr.rating,
    sr.comment
FROM sessions se
INNER JOIN mentorship_matches m ON m.id = se.match_id
INNER JOIN users mentor ON mentor.id = m.mentor_id
INNER JOIN skills sk ON sk.id = m.skill_id
INNER JOIN users mentee ON mentee.id = m.mentee_id
LEFT JOIN session_ratings sr ON sr.session_id = se.id
WHERE mentee.email = 'd.kuz@mail.com'
ORDER BY se.scheduled_at DESC;
