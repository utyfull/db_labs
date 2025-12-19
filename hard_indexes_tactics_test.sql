SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off;

-- A

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
WITH params AS (
  SELECT id AS skill_id FROM skills WHERE name = 'lab4_data_skill' LIMIT 1
),
recent_sessions AS (
  SELECT mm.mentor_id, s.id AS session_id
  FROM params p
  JOIN mentorship_matches mm ON mm.skill_id = p.skill_id
  JOIN sessions s ON s.match_id = mm.id
  WHERE mm.status IN ('active','completed')
    AND s.status = 'completed'
    AND s.scheduled_at >= now() - interval '180 days'
),
ratings AS (
  SELECT rs.mentor_id,
         count(*) AS rated_sessions,
         avg(sr.rating)::numeric(4,2) AS avg_rating
  FROM recent_sessions rs
  JOIN session_ratings sr ON sr.session_id = rs.session_id
  GROUP BY rs.mentor_id
)
SELECT u.id,
       u.full_name,
       us.proficiency,
       us.years_experience,
       coalesce(r.avg_rating, 0) AS avg_rating,
       coalesce(r.rated_sessions, 0) AS rated_sessions
FROM params p
JOIN user_skills us ON us.skill_id = p.skill_id
JOIN users u ON u.id = us.user_id
LEFT JOIN ratings r ON r.mentor_id = u.id
WHERE u.is_mentor = TRUE
  AND us.proficiency >= 7
  AND us.years_experience BETWEEN 2 AND 10
ORDER BY avg_rating DESC,
         rated_sessions DESC,
         us.proficiency DESC,
         us.years_experience DESC,
         u.id
LIMIT 50;

-- B

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
WITH req AS (
  SELECT mr.id, mr.mentee_id, mr.skill_id, mr.status, mr.created_at
  FROM mentorship_requests mr
  JOIN skills sk ON sk.id = mr.skill_id
  WHERE mr.status IN ('open','in_review')
    AND mr.created_at >= now() - interval '30 days'
    AND sk.name ILIKE '%data%'
),
app_stats AS (
  SELECT ma.request_id,
         count(*) FILTER (WHERE ma.status='pending') AS pending_apps,
         count(*) FILTER (WHERE ma.status='accepted') AS accepted_apps
  FROM mentorship_applications ma
  GROUP BY ma.request_id
),
match_stats AS (
  SELECT mm.request_id,
         count(*) FILTER (WHERE mm.status IN ('pending','active')) AS active_matches,
         count(*) FILTER (WHERE mm.status='completed') AS completed_matches
  FROM mentorship_matches mm
  WHERE mm.request_id IS NOT NULL
  GROUP BY mm.request_id
)
SELECT r.id AS request_id,
       u.full_name AS mentee_name,
       sk.name AS skill_name,
       r.status,
       r.created_at,
       coalesce(a.pending_apps,0) AS pending_apps,
       coalesce(a.accepted_apps,0) AS accepted_apps,
       coalesce(m.active_matches,0) AS active_matches,
       coalesce(m.completed_matches,0) AS completed_matches
FROM req r
JOIN users u ON u.id = r.mentee_id
JOIN skills sk ON sk.id = r.skill_id
LEFT JOIN app_stats a ON a.request_id = r.id
LEFT JOIN match_stats m ON m.request_id = r.id
ORDER BY pending_apps DESC, r.created_at DESC, r.id
LIMIT 100;

-- C

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
WITH demand AS (
  SELECT skill_id,
         count(*) FILTER (WHERE status IN ('open','in_review')) AS open_requests,
         count(*) AS total_requests
  FROM mentorship_requests
  WHERE created_at >= now() - interval '90 days'
  GROUP BY skill_id
),
supply AS (
  SELECT us.skill_id,
         count(*) FILTER (WHERE u.is_mentor AND us.proficiency >= 8) AS strong_mentors,
         count(*) FILTER (WHERE u.is_mentor) AS mentors_total
  FROM user_skills us
  JOIN users u ON u.id = us.user_id
  WHERE us.is_primary = TRUE
  GROUP BY us.skill_id
),
match_time AS (
  SELECT mm.skill_id,
         avg(extract(epoch from (mm.started_at - mr.created_at)) / 3600)::numeric(10,2) AS avg_hours_to_start,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY extract(epoch from (mm.started_at - mr.created_at)) / 3600)::numeric(10,2) AS p50_hours_to_start
  FROM mentorship_matches mm
  JOIN mentorship_requests mr ON mr.id = mm.request_id
  WHERE mm.request_id IS NOT NULL
    AND mm.started_at IS NOT NULL
    AND mr.created_at >= now() - interval '180 days'
  GROUP BY mm.skill_id
),
combined AS (
  SELECT sk.id AS skill_id,
         sk.name,
         coalesce(s.strong_mentors,0) AS strong_mentors,
         coalesce(s.mentors_total,0) AS mentors_total,
         coalesce(d.open_requests,0) AS open_requests,
         coalesce(d.total_requests,0) AS total_requests,
         mt.avg_hours_to_start,
         mt.p50_hours_to_start,
         CASE
           WHEN coalesce(d.open_requests,0) = 0 THEN NULL
           ELSE (coalesce(s.strong_mentors,0)::numeric / d.open_requests)::numeric(10,4)
         END AS strong_supply_to_open_demand
  FROM skills sk
  LEFT JOIN demand d ON d.skill_id = sk.id
  LEFT JOIN supply s ON s.skill_id = sk.id
  LEFT JOIN match_time mt ON mt.skill_id = sk.id
)
SELECT *,
       rank() OVER (ORDER BY strong_supply_to_open_demand NULLS LAST, open_requests DESC) AS priority_rank
FROM combined
WHERE open_requests >= 10
ORDER BY priority_rank, open_requests DESC, skill_id
LIMIT 200;

RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;

-- indexes 

CREATE INDEX lab4_users_created_at_brin
ON users
USING brin (created_at);

CREATE INDEX lab4_user_skills_skill_prof_exp_inc
ON user_skills (skill_id, proficiency DESC, years_experience DESC)
INCLUDE (user_id, is_primary);

CREATE INDEX lab4_user_skills_primary_skill_prof
ON user_skills (skill_id, proficiency DESC)
WHERE is_primary = TRUE;

CREATE INDEX lab4_mentorship_requests_open_recent
ON mentorship_requests (skill_id, created_at DESC)
WHERE status IN ('open','in_review');

CREATE INDEX lab4_mentorship_requests_created_brin
ON mentorship_requests
USING brin (created_at);

CREATE INDEX lab4_mentorship_applications_request_status_inc
ON mentorship_applications (request_id, status, created_at DESC)
INCLUDE (mentor_id);

CREATE INDEX lab4_mentorship_applications_pending_partial
ON mentorship_applications (request_id, created_at DESC)
WHERE status = 'pending';

CREATE INDEX lab4_mentorship_matches_skill_status_started_inc
ON mentorship_matches (skill_id, status, started_at DESC)
INCLUDE (mentor_id, request_id);

CREATE INDEX lab4_mentorship_matches_request_status
ON mentorship_matches (request_id, status)
WHERE request_id IS NOT NULL;

CREATE INDEX lab4_sessions_completed_partial
ON sessions (match_id, scheduled_at DESC)
WHERE status = 'completed';

CREATE INDEX lab4_session_ratings_session_inc
ON session_ratings (session_id)
INCLUDE (rating);

ANALYZE;

-- A B C -----//-------
SET enable_hashjoin = off;
SET enable_nestloop = on;
SET enable_mergejoin = on;


