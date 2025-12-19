-- 1

DROP INDEX IF EXISTS lab4_sessions_scheduled_at_brin;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT s.id, s.match_id, s.scheduled_at, s.status
FROM sessions s
WHERE s.scheduled_at >= now() - interval '30 days'
  AND s.scheduled_at < now()
ORDER BY s.scheduled_at DESC
LIMIT 200;

CREATE INDEX lab4_sessions_scheduled_at_brin
ON sessions
USING brin (scheduled_at);

ANALYZE sessions;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT s.id, s.match_id, s.scheduled_at, s.status
FROM sessions s
WHERE s.scheduled_at >= now() - interval '30 days'
  AND s.scheduled_at < now()
ORDER BY s.scheduled_at DESC
LIMIT 200;

-- 2

DROP INDEX IF EXISTS lab4_users_lower_full_name_prefix;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT u.id, u.full_name, u.email
FROM users u
WHERE u.is_mentor = TRUE
  AND lower(u.full_name) LIKE 'lab%'
ORDER BY u.full_name ASC
LIMIT 200;

CREATE INDEX lab4_users_lower_full_name_prefix
ON users ((lower(full_name)) text_pattern_ops)
WHERE is_mentor = TRUE;

ANALYZE users;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT u.id, u.full_name, u.email
FROM users u
WHERE u.is_mentor = TRUE
  AND lower(u.full_name) LIKE 'lab%'
ORDER BY u.full_name ASC
LIMIT 200;

-- 3

DROP INDEX IF EXISTS lab4_skills_name_trgm;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT sk.id, sk.name
FROM skills sk
WHERE sk.name ILIKE '%data%'
ORDER BY sk.name
LIMIT 200;

CREATE INDEX lab4_skills_name_trgm
ON skills
USING gin (name gin_trgm_ops);

ANALYZE skills;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT sk.id, sk.name
FROM skills sk
WHERE sk.name ILIKE '%data%'
ORDER BY sk.name
LIMIT 200;
