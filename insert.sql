INSERT INTO users (id, full_name, email, bio, avatar_url, is_mentor, is_mentee, created_at, updated_at) VALUES
(1, 'Иван Петров', 'ivan.petrov@mail.com', 'Backend dev, 7 лет', NULL, TRUE, FALSE, now(), now()),
(2, 'Анна Смирнова', 'anna.smirnova@mail.com', 'UX/UI дизайнер', NULL, TRUE, TRUE, now(), now()),
(3, 'Дмитрий Кузнецов', 'd.kuz@mail.com', 'Хочу в data science', NULL, FALSE, TRUE, now(), now()),
(4, 'Ольга Иванова', 'olga.ivanova@mail.com', 'Junior frontend', NULL, FALSE, TRUE, now(), now()),
(5, 'Сергей Леонов', 'sergey.leonov@mail.com', 'Карьерный консультант', NULL, TRUE, FALSE, now(), now()),
(6, 'Мария Орлова', 'maria.orlova@mail.com', 'Product manager', NULL, TRUE, TRUE, now(), now());

INSERT INTO skills (id, name, description, created_at) VALUES
(1, 'Python', 'Язык программирования и экосистема', now()),
(2, 'Frontend (React)', 'Разработка интерфейсов на React', now()),
(3, 'UX/UI Design', 'Проектирование пользовательских интерфейсов', now()),
(4, 'Data Science', 'ML, анализ данных', now()),
(5, 'Career', 'Карьерное развитие и собеседования', now());

INSERT INTO user_skills (user_id, skill_id, proficiency, years_experience, is_primary, added_at) VALUES
(1, 1, 9, 6.0, TRUE,  now()),
(1, 4, 7, 2.0, FALSE, now()),
(2, 3, 8, 5.0, TRUE,  now()),
(2, 2, 6, 2.5, FALSE, now()),
(3, 1, 5, 1.0, TRUE,  now()),
(3, 4, 4, 0.5, FALSE, now()),
(4, 2, 4, 0.8, TRUE,  now()),
(5, 5, 9, 8.0, TRUE,  now()),
(6, 5, 7, 3.0, FALSE, now()),
(6, 3, 6, 2.0, TRUE,  now());

INSERT INTO mentorship_requests (id, mentee_id, skill_id, goal, desired_proficiency, status, created_at, updated_at) VALUES
(1, 3, 4, 'Понять основы ML и сделать первый проект', 7, 'open', now(), now()),
(2, 4, 2, 'Подтянуть React и научиться делать SPA', 6, 'open', now(), now()),
(3, 3, 1, 'Углубить Python для аналитики', 8, 'in_review', now(), now()),
(4, 2, 5, 'Смена проекта и подготовка к интервью', 8, 'open', now(), now());

INSERT INTO mentorship_applications (id, request_id, mentor_id, message, status, created_at, updated_at) VALUES
(1, 1, 1, 'Могу помочь с базой ML на Python', 'pending', now(), now()),
(2, 1, 6, 'Есть опыт DS-проектов, готова вести', 'accepted', now(), now()),
(3, 2, 2, 'Практикую React, могу ускорить прогресс', 'accepted', now(), now()),
(4, 3, 1, 'Разберём Python продвинутый', 'pending', now(), now()),
(5, 4, 5, 'Помогу выстроить план карьерного роста', 'pending', now(), now());

INSERT INTO mentorship_matches (id, mentor_id, mentee_id, skill_id, request_id, status,
                               mentor_note, mentee_note, created_at, updated_at, started_at)
VALUES
(1, 6, 3, 4, 1, 'active', 'Фокус на практику', 'Хочу больше примеров', now(), now(), now()),
(2, 2, 4, 2, 2, 'active', NULL, NULL, now(), now(), now());

INSERT INTO sessions (id, match_id, scheduled_at, duration_minutes, status, meeting_link,
                      agenda, notes, created_at, updated_at)
VALUES
(1, 1, now() - interval '10 days', 60, 'completed', NULL, 'Введение в ML', 'Разобрали регрессию', now(), now()),
(2, 1, now() - interval '3 days', 90, 'completed', NULL, 'Классификация', 'ДЗ по sklearn', now(), now()),
(3, 2, now() - interval '7 days', 60, 'completed', NULL, 'Компоненты и props', 'Собрали мини-апп', now(), now()),
(4, 2, now() + interval '2 days', 60, 'scheduled', NULL, 'Hooks', NULL, now(), now());

INSERT INTO session_ratings (id, session_id, rater_id, rating, comment, created_at) VALUES
(1, 1, 3, 5, 'Очень понятно объяснили', now()),
(2, 2, 3, 4, 'Немного быстро, но полезно', now()),
(3, 3, 4, 5, 'Супер, стало яснее', now());
