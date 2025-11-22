-- кто в каких ролях
SELECT
  CASE
    WHEN is_mentor = TRUE  AND is_mentee = TRUE  THEN 'mentor+mentee'
    WHEN is_mentor = TRUE  AND is_mentee = FALSE THEN 'mentor_only'
    WHEN is_mentor = FALSE AND is_mentee = TRUE  THEN 'mentee_only'
    ELSE 'no_role'
  END AS role_type,
  COUNT(*) AS users_count
FROM users
GROUP BY role_type
ORDER BY users_count DESC;

-- сколько запросов в каждом статусе
SELECT
  status,
  COUNT(*) AS requests_count,
  MIN(created_at) AS first_request_at,
  MAX(created_at) AS last_request_at
FROM mentorship_requests
GROUP BY status
HAVING COUNT(*) >= 1
ORDER BY requests_count DESC;

-- активность по сессиям: сколько проведено, средняя длительность, суммарное время
SELECT
  status,
  COUNT(*) AS sessions_count,
  AVG(duration_minutes)::numeric(5,2) AS avg_duration_min,
  SUM(duration_minutes) AS total_duration_min,
  MIN(scheduled_at) AS first_session_at,
  MAX(scheduled_at) AS last_session_at
FROM sessions
GROUP BY status
ORDER BY sessions_count DESC;
