-- Bantora Clean-Slate Schema (V1)
-- Created: 2025-12-16

-- UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Users
CREATE TABLE bantora_user (
    phone_number VARCHAR(20) PRIMARY KEY,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(100),
    country_code VARCHAR(2) NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    preferred_language VARCHAR(5) NOT NULL DEFAULT 'en',
    preferred_currency VARCHAR(3),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

CREATE UNIQUE INDEX uq_bantora_user_email ON bantora_user(email) WHERE email IS NOT NULL;
CREATE INDEX idx_bantora_user_country ON bantora_user(country_code);
CREATE INDEX idx_bantora_user_verified ON bantora_user(verified);
CREATE INDEX idx_bantora_user_enabled ON bantora_user(enabled);

-- User roles
CREATE TABLE bantora_user_role (
    phone_number VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL,
    PRIMARY KEY (phone_number, role),
    FOREIGN KEY (phone_number) REFERENCES bantora_user(phone_number) ON DELETE CASCADE
);

CREATE INDEX idx_bantora_user_role_phone ON bantora_user_role(phone_number);

-- Countries (registration)
CREATE TABLE bantora_country (
    code VARCHAR(2) PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    calling_code VARCHAR(8) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    default_language VARCHAR(10) NOT NULL,
    registration_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX uq_bantora_country_code ON bantora_country(code);
CREATE INDEX idx_bantora_country_registration_enabled ON bantora_country(registration_enabled);
CREATE INDEX idx_bantora_country_name ON bantora_country(name);

-- Categories
CREATE TABLE bantora_category (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX ux_bantora_category_lower_name ON bantora_category (lower(name));
CREATE INDEX idx_bantora_category_name ON bantora_category(name);

-- Hashtags (stored without '#')
CREATE TABLE bantora_hashtag (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag VARCHAR(64) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_bantora_hashtag_tag_nonempty CHECK (length(trim(tag)) > 0)
);

CREATE UNIQUE INDEX ux_bantora_hashtag_lower_tag ON bantora_hashtag (lower(tag));
CREATE INDEX idx_bantora_hashtag_tag ON bantora_hashtag(tag);

-- Polls
CREATE TABLE bantora_poll (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    creator_phone VARCHAR(20) NOT NULL,
    category_id UUID NOT NULL,
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
    FOREIGN KEY (creator_phone) REFERENCES bantora_user(phone_number),
    FOREIGN KEY (category_id) REFERENCES bantora_category(id)
);

CREATE INDEX idx_bantora_poll_creator ON bantora_poll(creator_phone);
CREATE INDEX idx_bantora_poll_category ON bantora_poll(category_id);
CREATE INDEX idx_bantora_poll_scope ON bantora_poll(scope);
CREATE INDEX idx_bantora_poll_status ON bantora_poll(status);
CREATE INDEX idx_bantora_poll_region ON bantora_poll(region);
CREATE INDEX idx_bantora_poll_country ON bantora_poll(country_code);
CREATE INDEX idx_bantora_poll_start_time ON bantora_poll(start_time);
CREATE INDEX idx_bantora_poll_end_time ON bantora_poll(end_time);

-- Poll options
CREATE TABLE bantora_poll_option (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL,
    option_text VARCHAR(500) NOT NULL,
    option_order INTEGER NOT NULL,
    votes_count BIGINT NOT NULL DEFAULT 0,
    FOREIGN KEY (poll_id) REFERENCES bantora_poll(id) ON DELETE CASCADE
);

CREATE INDEX idx_bantora_poll_option_poll ON bantora_poll_option(poll_id);

-- Votes
CREATE TABLE bantora_vote (
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

CREATE INDEX idx_bantora_vote_poll ON bantora_vote(poll_id);
CREATE INDEX idx_bantora_vote_user ON bantora_vote(user_phone);
CREATE INDEX idx_bantora_vote_timestamp ON bantora_vote(voted_at);

-- Ideas
CREATE TABLE bantora_idea (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_phone VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    category_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL,
    ai_summary TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    upvotes BIGINT NOT NULL DEFAULT 0,
    FOREIGN KEY (user_phone) REFERENCES bantora_user(phone_number),
    FOREIGN KEY (category_id) REFERENCES bantora_category(id)
);

CREATE INDEX idx_bantora_idea_user ON bantora_idea(user_phone);
CREATE INDEX idx_bantora_idea_status ON bantora_idea(status);
CREATE INDEX idx_bantora_idea_created ON bantora_idea(created_at);
CREATE INDEX idx_bantora_idea_category ON bantora_idea(category_id);

-- Idea <-> Hashtag
CREATE TABLE bantora_idea_hashtag (
    idea_id UUID NOT NULL,
    hashtag_id UUID NOT NULL,
    PRIMARY KEY (idea_id, hashtag_id),
    FOREIGN KEY (idea_id) REFERENCES bantora_idea(id) ON DELETE CASCADE,
    FOREIGN KEY (hashtag_id) REFERENCES bantora_hashtag(id) ON DELETE CASCADE
);

CREATE INDEX idx_bantora_idea_hashtag_idea ON bantora_idea_hashtag(idea_id);
CREATE INDEX idx_bantora_idea_hashtag_hashtag ON bantora_idea_hashtag(hashtag_id);

-- Enforce: each idea must have at least one hashtag (transactional)
CREATE OR REPLACE FUNCTION bantora_enforce_idea_hashtags() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM bantora_idea_hashtag WHERE idea_id = NEW.id) THEN
        RAISE EXCEPTION 'Idea % must have at least one hashtag', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER bantora_trg_idea_hashtags
AFTER INSERT OR UPDATE ON bantora_idea
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION bantora_enforce_idea_hashtags();

-- Poll <-> Hashtag (for filtering)
CREATE TABLE bantora_poll_hashtag (
    poll_id UUID NOT NULL,
    hashtag_id UUID NOT NULL,
    PRIMARY KEY (poll_id, hashtag_id),
    FOREIGN KEY (poll_id) REFERENCES bantora_poll(id) ON DELETE CASCADE,
    FOREIGN KEY (hashtag_id) REFERENCES bantora_hashtag(id) ON DELETE CASCADE
);

CREATE INDEX idx_bantora_poll_hashtag_poll ON bantora_poll_hashtag(poll_id);
CREATE INDEX idx_bantora_poll_hashtag_hashtag ON bantora_poll_hashtag(hashtag_id);

-- Poll <-> Source Idea (traceability)
CREATE TABLE bantora_poll_source_idea (
    poll_id UUID NOT NULL,
    idea_id UUID NOT NULL,
    PRIMARY KEY (poll_id, idea_id),
    FOREIGN KEY (poll_id) REFERENCES bantora_poll(id) ON DELETE CASCADE,
    FOREIGN KEY (idea_id) REFERENCES bantora_idea(id) ON DELETE CASCADE
);

CREATE INDEX idx_bantora_poll_source_idea_poll ON bantora_poll_source_idea(poll_id);
CREATE INDEX idx_bantora_poll_source_idea_idea ON bantora_poll_source_idea(idea_id);

-- Refresh tokens
CREATE TABLE bantora_refresh_token (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token VARCHAR(500) NOT NULL UNIQUE,
    user_phone VARCHAR(20) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_phone) REFERENCES bantora_user(phone_number) ON DELETE CASCADE
);

CREATE INDEX idx_bantora_refresh_token_token ON bantora_refresh_token(token);
CREATE INDEX idx_bantora_refresh_token_user ON bantora_refresh_token(user_phone);
CREATE INDEX idx_bantora_refresh_token_expires ON bantora_refresh_token(expires_at);
