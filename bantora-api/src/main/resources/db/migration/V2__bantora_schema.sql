-- Bantora Database Schema V2
-- Created: 2025-12-11
-- R2DBC/Flyway migration

-- Users table
CREATE TABLE IF NOT EXISTS bantora_users (
    phone_number VARCHAR(20) PRIMARY KEY,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(100),
    country_code VARCHAR(2) NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    preferred_language VARCHAR(5) NOT NULL DEFAULT 'en',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_country ON bantora_users(country_code);
CREATE INDEX IF NOT EXISTS idx_users_verified ON bantora_users(verified);
CREATE INDEX IF NOT EXISTS idx_users_enabled ON bantora_users(enabled);

-- User roles table
CREATE TABLE IF NOT EXISTS bantora_user_roles (
    phone_number VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL,
    PRIMARY KEY (phone_number, role),
    FOREIGN KEY (phone_number) REFERENCES bantora_users(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_roles_phone ON bantora_user_roles(phone_number);

-- Polls table
CREATE TABLE IF NOT EXISTS bantora_polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    creator_phone VARCHAR(20) NOT NULL,
    category VARCHAR(50),
    scope VARCHAR(20) NOT NULL,
    region VARCHAR(50),
    country_code VARCHAR(2),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    allow_anonymous BOOLEAN NOT NULL DEFAULT TRUE,
    allow_multiple_votes BOOLEAN NOT NULL DEFAULT FALSE,
    total_votes BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (creator_phone) REFERENCES bantora_users(phone_number)
);

CREATE INDEX IF NOT EXISTS idx_polls_creator ON bantora_polls(creator_phone);
CREATE INDEX IF NOT EXISTS idx_polls_scope ON bantora_polls(scope);
CREATE INDEX IF NOT EXISTS idx_polls_status ON bantora_polls(status);
CREATE INDEX IF NOT EXISTS idx_polls_region ON bantora_polls(region);
CREATE INDEX IF NOT EXISTS idx_polls_country ON bantora_polls(country_code);
CREATE INDEX IF NOT EXISTS idx_polls_start_time ON bantora_polls(start_time);
CREATE INDEX IF NOT EXISTS idx_polls_end_time ON bantora_polls(end_time);

-- Poll options table
CREATE TABLE IF NOT EXISTS bantora_poll_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL,
    option_text VARCHAR(500) NOT NULL,
    option_order INTEGER NOT NULL,
    votes_count BIGINT NOT NULL DEFAULT 0,
    FOREIGN KEY (poll_id) REFERENCES bantora_polls(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_poll_options_poll ON bantora_poll_options(poll_id);

-- Votes table
CREATE TABLE IF NOT EXISTS bantora_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL,
    option_id UUID NOT NULL,
    user_phone VARCHAR(20),
    anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    voted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    FOREIGN KEY (poll_id) REFERENCES bantora_polls(id) ON DELETE CASCADE,
    FOREIGN KEY (option_id) REFERENCES bantora_poll_options(id) ON DELETE CASCADE,
    FOREIGN KEY (user_phone) REFERENCES bantora_users(phone_number) ON DELETE SET NULL,
    CONSTRAINT unique_poll_user UNIQUE (poll_id, user_phone)
);

CREATE INDEX IF NOT EXISTS idx_votes_poll ON bantora_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_votes_user ON bantora_votes(user_phone);
CREATE INDEX IF NOT EXISTS idx_votes_timestamp ON bantora_votes(voted_at);

-- Ideas table
CREATE TABLE IF NOT EXISTS bantora_ideas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_phone VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL,
    ai_summary TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    upvotes BIGINT NOT NULL DEFAULT 0,
    FOREIGN KEY (user_phone) REFERENCES bantora_users(phone_number)
);

CREATE INDEX IF NOT EXISTS idx_ideas_user ON bantora_ideas(user_phone);
CREATE INDEX IF NOT EXISTS idx_ideas_status ON bantora_ideas(status);
CREATE INDEX IF NOT EXISTS idx_ideas_created ON bantora_ideas(created_at);
