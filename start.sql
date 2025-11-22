CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    bio TEXT,
    avatar_url TEXT,
    is_mentor BOOLEAN NOT NULL DEFAULT FALSE,
    is_mentee BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE skills (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE user_skills (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_id BIGINT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    proficiency SMALLINT NOT NULL CHECK (proficiency BETWEEN 1 AND 10),
    years_experience NUMERIC(4,1) NOT NULL DEFAULT 0 CHECK (years_experience >= 0),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    added_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, skill_id)
);

CREATE TABLE mentorship_requests (
    id BIGSERIAL PRIMARY KEY,
    mentee_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_id BIGINT NOT NULL REFERENCES skills(id) ON DELETE RESTRICT,

    goal TEXT NOT NULL,
    desired_proficiency SMALLINT CHECK (desired_proficiency BETWEEN 1 AND 10),

    status TEXT NOT NULL DEFAULT 'open'
        CHECK (status IN ('open','in_review','matched','cancelled','closed')),

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE mentorship_applications (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES mentorship_requests(id) ON DELETE CASCADE,
    mentor_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    message TEXT,

    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','accepted','rejected','withdrawn')),

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

    UNIQUE (request_id, mentor_id)
);

CREATE TABLE mentorship_matches (
    id BIGSERIAL PRIMARY KEY,
    mentor_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mentee_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_id BIGINT NOT NULL REFERENCES skills(id) ON DELETE RESTRICT,

    request_id BIGINT REFERENCES mentorship_requests(id) ON DELETE SET NULL,

    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','active','completed','cancelled')),

    mentor_note TEXT,
    mentee_note TEXT,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancel_reason TEXT,

    CHECK (mentor_id <> mentee_id),
    UNIQUE (mentor_id, mentee_id, skill_id)
);

CREATE TABLE sessions (
    id BIGSERIAL PRIMARY KEY,
    match_id BIGINT NOT NULL REFERENCES mentorship_matches(id) ON DELETE CASCADE,

    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),

    status TEXT NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled','completed','cancelled','no_show')),

    meeting_link TEXT,
    agenda TEXT,
    notes TEXT,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancel_reason TEXT,

    UNIQUE (match_id, scheduled_at)
);

CREATE TABLE session_ratings (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    rater_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

    UNIQUE (session_id, rater_id)
);
