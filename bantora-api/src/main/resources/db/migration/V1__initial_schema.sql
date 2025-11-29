-- Created by Cascade AI
-- Author       : Tsungai Kaviya
-- Copyright    : TeraTech Solutions (Pvt) Ltd
-- Date/Time    : 2025-11-28
-- Email        : tkaviya@t3ratech.co.zw

-- Users table
CREATE TABLE users (
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

CREATE INDEX idx_users_country ON users(country_code);
CREATE INDEX idx_users_verified ON users(verified);
CREATE INDEX idx_users_enabled ON users(enabled);

-- User roles table
CREATE TABLE user_roles (
    phone_number VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL,
    PRIMARY KEY (phone_number, role),
    FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

CREATE INDEX idx_user_roles_phone ON user_roles(phone_number);

-- Polls table
CREATE TABLE polls (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    creator_phone VARCHAR(20) NOT NULL,
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
    FOREIGN KEY (creator_phone) REFERENCES users(phone_number)
);

CREATE INDEX idx_polls_creator ON polls(creator_phone);
CREATE INDEX idx_polls_scope ON polls(scope);
CREATE INDEX idx_polls_status ON polls(status);
CREATE INDEX idx_polls_region ON polls(region);
CREATE INDEX idx_polls_country ON polls(country_code);
CREATE INDEX idx_polls_start_time ON polls(start_time);
CREATE INDEX idx_polls_end_time ON polls(end_time);

-- Poll options table
CREATE TABLE poll_options (
    id UUID PRIMARY KEY,
    poll_id UUID NOT NULL,
    option_text VARCHAR(500) NOT NULL,
    option_order INTEGER NOT NULL,
    votes_count BIGINT NOT NULL DEFAULT 0,
    FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE
);

CREATE INDEX idx_poll_options_poll ON poll_options(poll_id);

-- Votes table
CREATE TABLE votes (
    id UUID PRIMARY KEY,
    poll_id UUID NOT NULL,
    option_id UUID NOT NULL,
    user_phone VARCHAR(20),
    anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    voted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE,
    FOREIGN KEY (option_id) REFERENCES poll_options(id) ON DELETE CASCADE,
    FOREIGN KEY (user_phone) REFERENCES users(phone_number) ON DELETE SET NULL,
    CONSTRAINT unique_poll_user UNIQUE (poll_id, user_phone)
);

CREATE INDEX idx_votes_poll ON votes(poll_id);
CREATE INDEX idx_votes_user ON votes(user_phone);
CREATE INDEX idx_votes_timestamp ON votes(voted_at);

-- Verification codes table
CREATE TABLE verification_codes (
    phone_number VARCHAR(20) PRIMARY KEY,
    code VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_verification_expires ON verification_codes(expires_at);

-- Refresh tokens table
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY,
    token VARCHAR(500) NOT NULL UNIQUE,
    user_phone VARCHAR(20) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_phone) REFERENCES users(phone_number) ON DELETE CASCADE
);

CREATE INDEX idx_refresh_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_user ON refresh_tokens(user_phone);
CREATE INDEX idx_refresh_expires ON refresh_tokens(expires_at);

-- Audit logs table (for tracking important actions)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY,
    action VARCHAR(100) NOT NULL,
    user_phone VARCHAR(20),
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    details TEXT,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_phone) REFERENCES users(phone_number) ON DELETE SET NULL
);

CREATE INDEX idx_audit_user ON audit_logs(user_phone);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(created_at);
