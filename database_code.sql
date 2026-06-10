
-- CREATE DATABASE twitter_engagement;
-- Table Creation
CREATE TABLE IF NOT EXISTS tweets (
    tweet_id TEXT PRIMARY KEY,
    author_id TEXT,
    created_at TIMESTAMP,
    text TEXT,
    clean_text TEXT,
    lang TEXT,

    retweet_count INT,
    reply_count INT,
    like_count INT,
    quote_count INT,

    has_media BOOLEAN DEFAULT FALSE,
    media_count INT DEFAULT 0,

    raw_json JSONB,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tweet_media (
    media_key TEXT PRIMARY KEY,
    tweet_id TEXT REFERENCES tweets(tweet_id),

    media_type TEXT,
    url TEXT,
    preview_image_url TEXT,
    alt_text TEXT,

    width INT,
    height INT,
    duration_ms INT,

    public_metrics JSONB,
    raw_json JSONB,

    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tweet_labels (
    tweet_id TEXT PRIMARY KEY REFERENCES tweets(tweet_id),

    is_engagement_bait BOOLEAN,
    label_confidence NUMERIC,
    label_reason TEXT,
    media_context_used BOOLEAN,

    labeled_by TEXT,
    labeled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    author_id TEXT PRIMARY KEY,
    username TEXT,
    name TEXT,
    verified BOOLEAN,

    followers_count INT,
    following_count INT,
    tweet_count INT,
    listed_count INT,

    raw_json JSONB,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Adding additional columns to track collection source and api search query
ALTER TABLE tweets
ADD COLUMN IF NOT EXISTS collection_source TEXT;

ALTER TABLE tweets
ADD COLUMN IF NOT EXISTS search_query TEXT;

-- Verifying correct table creation
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tweets'
ORDER BY ordinal_position;