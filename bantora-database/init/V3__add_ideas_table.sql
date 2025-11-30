-- Create ideas table
CREATE TABLE ideas (
    id UUID PRIMARY KEY,
    user_phone VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    upvotes BIGINT NOT NULL DEFAULT 0
);

-- Add index for ideas status
CREATE INDEX idx_ideas_status ON ideas(status);
CREATE INDEX idx_ideas_user_phone ON ideas(user_phone);

-- Update polls table
ALTER TABLE polls ADD COLUMN idea_id UUID REFERENCES ideas(id);
ALTER TABLE polls DROP COLUMN allow_anonymous;
ALTER TABLE polls DROP COLUMN allow_multiple_votes;

-- Update votes table
ALTER TABLE votes DROP COLUMN anonymous;
