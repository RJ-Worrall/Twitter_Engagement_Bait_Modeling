-- ============================================================
-- Twitter Engagement Bait Modeling Database Schema
-- Database: twitter_engagement
-- ============================================================

-- CREATE DATABASE twitter_engagement;


-- ============================================================
-- Table Creation
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    author_id TEXT PRIMARY KEY,
    username TEXT,
    name TEXT,
    verified BOOLEAN,

    followers_count INT,
    following_count INT,
    tweet_count INT,
    listed_count INT,
    user_like_count INT,
    user_media_count INT,

    eligible_for_labeling BOOLEAN DEFAULT FALSE,

    raw_json JSONB,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS tweets (
    tweet_id TEXT PRIMARY KEY,
    author_id TEXT REFERENCES users(author_id),

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

    collection_source TEXT,
    search_query TEXT,

    eligible_for_labeling BOOLEAN DEFAULT FALSE,

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

    eligible_for_labeling BOOLEAN DEFAULT FALSE,

    raw_json JSONB,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS tweet_labels (
    tweet_id TEXT PRIMARY KEY REFERENCES tweets(tweet_id),

    engagement_label TEXT,
    is_engagement_bait BOOLEAN,
    is_manipulative_bait BOOLEAN,

    label_confidence NUMERIC,
    label_reason TEXT,
    bait_type TEXT,
    media_context_used BOOLEAN,

    labeled_by TEXT,
    labeled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- Safe Schema Updates for Existing Tables
-- These are needed because CREATE TABLE IF NOT EXISTS does NOT
-- modify tables that already exist.
-- ============================================================

ALTER TABLE users
ADD COLUMN IF NOT EXISTS listed_count INT;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS user_like_count INT;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS user_media_count INT;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS eligible_for_labeling BOOLEAN DEFAULT FALSE;


ALTER TABLE tweets
ADD COLUMN IF NOT EXISTS collection_source TEXT;

ALTER TABLE tweets
ADD COLUMN IF NOT EXISTS search_query TEXT;

ALTER TABLE tweets
ADD COLUMN IF NOT EXISTS eligible_for_labeling BOOLEAN DEFAULT FALSE;


ALTER TABLE tweet_media
ADD COLUMN IF NOT EXISTS eligible_for_labeling BOOLEAN DEFAULT FALSE;


ALTER TABLE tweet_labels
ADD COLUMN IF NOT EXISTS engagement_label TEXT;

ALTER TABLE tweet_labels
ADD COLUMN IF NOT EXISTS is_manipulative_bait BOOLEAN;

ALTER TABLE tweet_labels
ADD COLUMN IF NOT EXISTS bait_type TEXT;

ALTER TABLE users
ALTER COLUMN followers_count TYPE BIGINT,
ALTER COLUMN following_count TYPE BIGINT,
ALTER COLUMN tweet_count TYPE BIGINT,
ALTER COLUMN listed_count TYPE BIGINT,
ALTER COLUMN user_like_count TYPE BIGINT,
ALTER COLUMN user_media_count TYPE BIGINT;

ALTER TABLE tweets
ALTER COLUMN retweet_count TYPE BIGINT,
ALTER COLUMN reply_count TYPE BIGINT,
ALTER COLUMN like_count TYPE BIGINT,
ALTER COLUMN quote_count TYPE BIGINT;

ALTER TABLE tweet_media
ALTER COLUMN width TYPE BIGINT,
ALTER COLUMN height TYPE BIGINT,
ALTER COLUMN duration_ms TYPE BIGINT;


-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_tweets_author_id
ON tweets(author_id);

CREATE INDEX IF NOT EXISTS idx_tweets_created_at
ON tweets(created_at);

CREATE INDEX IF NOT EXISTS idx_tweets_collection_source
ON tweets(collection_source);

CREATE INDEX IF NOT EXISTS idx_tweets_eligible_for_labeling
ON tweets(eligible_for_labeling);

CREATE INDEX IF NOT EXISTS idx_tweet_media_tweet_id
ON tweet_media(tweet_id);

CREATE INDEX IF NOT EXISTS idx_users_eligible_for_labeling
ON users(eligible_for_labeling);




-- ============================================================
-- Verification Queries
-- ============================================================

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tweets'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tweet_media'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tweet_labels'
ORDER BY ordinal_position;

-- Testing primary key's joining ability

SELECT
    t.tweet_id,
    u.username,
    t.like_count,
    t.eligible_for_labeling,
    m.media_type
FROM tweets t
LEFT JOIN users u
    ON t.author_id = u.author_id
LEFT JOIN tweet_media m
    ON t.tweet_id = m.tweet_id
LIMIT 20;

-- Veryifying tweets with more than 1 media are filtered correctly

SELECT *
FROM tweet_media
WHERE tweet_id = '2062900884644991276';

-- No duplicate tweets
SELECT tweet_id, COUNT(*)
FROM tweets
GROUP BY tweet_id
HAVING COUNT(*) > 1;

-- No duplicate users
SELECT author_id, COUNT(*)
FROM users
GROUP BY author_id
HAVING COUNT(*) > 1;

-- No duplicate media
SELECT media_key, COUNT(*)
FROM tweet_media
GROUP BY media_key
HAVING COUNT(*) > 1;

-- Checking how many tweets are eligible for labeling, sorted by engagment
SELECT retweet_count, reply_count, like_count, quote_count,
	(retweet_count + reply_count + like_count + quote_count) AS engagement_count
FROM tweets
WHERE eligible_for_labeling = true
ORDER BY engagement_count DESC;

