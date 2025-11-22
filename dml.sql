BEGIN;

-- 1) INSERT: временный пользователь
WITH new_user AS (
  INSERT INTO users (full_name, email, bio, is_mentor, is_mentee)
  VALUES (
    'Temp User Lab2',
    'temp_user_lab2_' || extract(epoch from now()) || '@example.com',
    'Временный пользователь для DML',
    FALSE,
    TRUE
  )
  RETURNING id, email
),
new_request AS (
  -- 2) INSERT: временный запрос от этого пользователя
  INSERT INTO mentorship_requests (mentee_id, skill_id, goal, desired_proficiency, status)
  VALUES (
    (SELECT id FROM new_user),
    (SELECT id FROM skills ORDER BY id LIMIT 1),
    'Temp goal for lab2',
    5,
    'open'
  )
  RETURNING id
)
-- 3) UPDATE: меняем статус только что созданного запроса
UPDATE mentorship_requests
SET status = 'closed',
    updated_at = now()
WHERE id = (SELECT id FROM new_request);


-- 4) DELETE: удаляем тестовый запрос
WITH last_request AS (
  SELECT id 
  FROM mentorship_requests 
  WHERE goal = 'Temp goal for lab2'
  ORDER BY created_at DESC
  LIMIT 1
)
DELETE FROM mentorship_requests
WHERE id = (SELECT id FROM last_request);


-- 5) DELETE: удаляем тестового пользователя
WITH last_user AS (
  SELECT id
  FROM users
  WHERE full_name = 'Temp User Lab2'
  ORDER BY created_at DESC
  LIMIT 1
)
DELETE FROM users
WHERE id = (SELECT id FROM last_user);

COMMIT;

SELECT
  'OK: тестовые данные вставлены, обновлены и удалены' AS message,
  (SELECT COUNT(*) FROM users WHERE full_name='Temp User Lab2') AS temp_users_left,
  (SELECT COUNT(*) FROM mentorship_requests WHERE goal='Temp goal for lab2') AS temp_requests_left;
