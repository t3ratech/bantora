-- Bantora Database Schema V2
-- Created: 2025-12-11
-- R2DBC/Flyway migration

-- Users table
CREATE TABLE IF NOT EXISTS bantora_user (
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

CREATE INDEX IF NOT EXISTS idx_bantora_user_country ON bantora_user(country_code);
CREATE INDEX IF NOT EXISTS idx_bantora_user_verified ON bantora_user(verified);
CREATE INDEX IF NOT EXISTS idx_bantora_user_enabled ON bantora_user(enabled);

-- User roles table
CREATE TABLE IF NOT EXISTS bantora_user_role (
    phone_number VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL,
    PRIMARY KEY (phone_number, role),
    FOREIGN KEY (phone_number) REFERENCES bantora_user(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_bantora_user_role_phone ON bantora_user_role(phone_number);

-- Polls table
CREATE TABLE IF NOT EXISTS bantora_poll (
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
    FOREIGN KEY (creator_phone) REFERENCES bantora_user(phone_number)
);

CREATE INDEX IF NOT EXISTS idx_bantora_poll_creator ON bantora_poll(creator_phone);
CREATE INDEX IF NOT EXISTS idx_bantora_poll_scope ON bantora_poll(scope);
CREATE INDEX IF NOT EXISTS idx_bantora_poll_status ON bantora_poll(status);
CREATE INDEX IF NOT EXISTS idx_bantora_poll_region ON bantora_poll(region);
CREATE INDEX IF NOT EXISTS idx_bantora_poll_country ON bantora_poll(country_code);
CREATE INDEX IF NOT EXISTS idx_bantora_poll_start_time ON bantora_poll(start_time);
CREATE INDEX IF NOT EXISTS idx_bantora_poll_end_time ON bantora_poll(end_time);

-- Poll options table
CREATE TABLE IF NOT EXISTS bantora_poll_option (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL,
    option_text VARCHAR(500) NOT NULL,
    option_order INTEGER NOT NULL,
    votes_count BIGINT NOT NULL DEFAULT 0,
    FOREIGN KEY (poll_id) REFERENCES bantora_poll(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_bantora_poll_option_poll ON bantora_poll_option(poll_id);

-- Votes table
CREATE TABLE IF NOT EXISTS bantora_vote (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL,
    option_id UUID NOT NULL,
    user_phone VARCHAR(20),
    anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    voted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    FOREIGN KEY (poll_id) REFERENCES bantora_poll(id) ON DELETE CASCADE,
    FOREIGN KEY (option_id) REFERENCES bantora_poll_option(id) ON DELETE CASCADE,
    FOREIGN KEY (user_phone) REFERENCES bantora_user(phone_number) ON DELETE SET NULL,
    CONSTRAINT unique_poll_user UNIQUE (poll_id, user_phone)
);

CREATE INDEX IF NOT EXISTS idx_bantora_vote_poll ON bantora_vote(poll_id);
CREATE INDEX IF NOT EXISTS idx_bantora_vote_user ON bantora_vote(user_phone);
CREATE INDEX IF NOT EXISTS idx_bantora_vote_timestamp ON bantora_vote(voted_at);

-- Ideas table
CREATE TABLE IF NOT EXISTS bantora_idea (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_phone VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL,
    ai_summary TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    upvotes BIGINT NOT NULL DEFAULT 0,
    FOREIGN KEY (user_phone) REFERENCES bantora_user(phone_number)
);

CREATE INDEX IF NOT EXISTS idx_bantora_idea_user ON bantora_idea(user_phone);
CREATE INDEX IF NOT EXISTS idx_bantora_idea_status ON bantora_idea(status);
CREATE INDEX IF NOT EXISTS idx_bantora_idea_created ON bantora_idea(created_at);

-- Verification codes table
CREATE TABLE IF NOT EXISTS bantora_verification_code (
    phone_number VARCHAR(20) PRIMARY KEY,
    code VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (phone_number) REFERENCES bantora_user(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_bantora_verification_code_expires ON bantora_verification_code(expires_at);
CREATE INDEX IF NOT EXISTS idx_bantora_verification_code_verified ON bantora_verification_code(verified);

-- Refresh tokens table
CREATE TABLE IF NOT EXISTS bantora_refresh_token (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token VARCHAR(500) NOT NULL UNIQUE,
    user_phone VARCHAR(20) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_phone) REFERENCES bantora_user(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_bantora_refresh_token_token ON bantora_refresh_token(token);
CREATE INDEX IF NOT EXISTS idx_bantora_refresh_token_user ON bantora_refresh_token(user_phone);
CREATE INDEX IF NOT EXISTS idx_bantora_refresh_token_expires ON bantora_refresh_token(expires_at);
