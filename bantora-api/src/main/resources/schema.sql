CREATE TABLE IF NOT EXISTS ideas (
    id UUID PRIMARY KEY,
    user_phone VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    processed_at TIMESTAMP,
    upvotes BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS polls (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    creator_phone VARCHAR(20) NOT NULL,
    idea_id UUID,
    scope VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL,
    votes_count BIGINT NOT NULL DEFAULT 0
);
