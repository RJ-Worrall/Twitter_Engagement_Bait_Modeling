






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

-- Veryifying tweets with more than 1 media are filte

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

SELECT * 
FROM tweets
WHERE eligible_for_labeling = true

SELECT * 
FROM tweets
WHERE eligible_for_labeling = true AND collection_source = 'engagement_grok';

SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'tweet_media'
ORDER BY ORDINAL_POSITION;

SELECT user_like_count, user_media_count
FROM users
WHERE user_like_count IS NOT NULL
AND user_media_count IS NOT NULL

ALTER TABLE tweet_labels
RENAME COLUMN is_manipulative_bait TO is_harmful_bait;

SELECT column_name
FROM information_schema.columns
WHERE table_name='tweet_labels';

-- ============================================================
-- Rebuild modeling dataset table
-- One row per labeled tweet
-- ============================================================

DROP TABLE IF EXISTS tweet_modeling_dataset;

CREATE TABLE tweet_modeling_dataset AS
WITH media_summary AS (
    SELECT
        tweet_id,

        COUNT(media_key) AS media_count_from_media_table,

        SUM(CASE WHEN media_type = 'photo' THEN 1 ELSE 0 END) AS num_photos,
        SUM(CASE WHEN media_type = 'video' THEN 1 ELSE 0 END) AS num_videos,
        SUM(CASE WHEN media_type = 'animated_gif' THEN 1 ELSE 0 END) AS num_gifs,

        MAX(CASE WHEN media_type = 'photo' THEN 1 ELSE 0 END) AS has_photo,
        MAX(CASE WHEN media_type = 'video' THEN 1 ELSE 0 END) AS has_video,
        MAX(CASE WHEN media_type = 'animated_gif' THEN 1 ELSE 0 END) AS has_gif,

        SUM(CASE WHEN alt_text IS NOT NULL THEN 1 ELSE 0 END) AS num_alt_text,
        MAX(CASE WHEN alt_text IS NOT NULL THEN 1 ELSE 0 END) AS has_alt_text,

        MAX(width) AS max_media_width,
        MAX(height) AS max_media_height,
        MAX(duration_ms) AS max_duration_ms,

        AVG(width) AS avg_media_width,
        AVG(height) AS avg_media_height,

        STRING_AGG(DISTINCT media_type, ', ') AS media_types

    FROM tweet_media
    GROUP BY tweet_id
)

SELECT
    -- ========================================================
    -- IDs
    -- ========================================================
    t.tweet_id,
    t.author_id,

    -- ========================================================
    -- Tweet text/features
    -- ========================================================
    t.text,
    t.clean_text,
    t.created_at,
    t.lang,

    LENGTH(t.text) AS text_length,

    CASE
        WHEN LENGTH(t.text) > 0
        THEN LENGTH(REGEXP_REPLACE(t.text, '[^A-Z]', '', 'g'))::FLOAT / LENGTH(t.text)
        ELSE 0
    END AS uppercase_ratio,

    LENGTH(t.text) - LENGTH(REPLACE(t.text, '!', '')) AS exclamation_count,
    LENGTH(t.text) - LENGTH(REPLACE(t.text, '?', '')) AS question_count,

    CASE WHEN POSITION('http' IN t.text) > 0 THEN 1 ELSE 0 END AS has_url,
    CASE WHEN POSITION('@' IN t.text) > 0 THEN 1 ELSE 0 END AS has_mention,
    CASE WHEN POSITION('#' IN t.text) > 0 THEN 1 ELSE 0 END AS has_hashtag,

    -- ========================================================
    -- Tweet engagement metrics
    -- ========================================================
    t.like_count,
    t.reply_count,
    t.retweet_count,
    t.quote_count,

    (
        COALESCE(t.like_count, 0)
        + COALESCE(t.reply_count, 0)
        + COALESCE(t.retweet_count, 0)
        + COALESCE(t.quote_count, 0)
    ) AS engagement_total,

    CASE
        WHEN COALESCE(t.like_count, 0) > 0
        THEN t.reply_count::FLOAT / t.like_count
        ELSE NULL
    END AS reply_like_ratio,

    CASE
        WHEN COALESCE(t.like_count, 0) > 0
        THEN t.quote_count::FLOAT / t.like_count
        ELSE NULL
    END AS quote_like_ratio,

    -- ========================================================
    -- Collection metadata
    -- ========================================================
    t.collection_source,
    t.search_query,

    -- ========================================================
    -- User/account features
    -- ========================================================
    u.username,
    u.name AS display_name,
    u.verified,

    u.followers_count,
    u.following_count,
    u.tweet_count AS user_tweet_count,
    u.listed_count,
    u.user_like_count,
    u.user_media_count,

    CASE
        WHEN COALESCE(u.following_count, 0) > 0
        THEN u.followers_count::FLOAT / u.following_count
        ELSE NULL
    END AS follower_following_ratio,

    -- ========================================================
    -- Media aggregate features
    -- ========================================================
    t.has_media,
    COALESCE(t.media_count, 0) AS tweet_reported_media_count,

    COALESCE(ms.media_count_from_media_table, 0) AS media_count_from_media_table,
    COALESCE(ms.num_photos, 0) AS num_photos,
    COALESCE(ms.num_videos, 0) AS num_videos,
    COALESCE(ms.num_gifs, 0) AS num_gifs,

    COALESCE(ms.has_photo, 0) AS has_photo,
    COALESCE(ms.has_video, 0) AS has_video,
    COALESCE(ms.has_gif, 0) AS has_gif,

    COALESCE(ms.num_alt_text, 0) AS num_alt_text,
    COALESCE(ms.has_alt_text, 0) AS has_alt_text,

    ms.max_media_width,
    ms.max_media_height,
    ms.max_duration_ms,
    ms.avg_media_width,
    ms.avg_media_height,
    ms.media_types,

    -- ========================================================
    -- Label columns / target
    -- ========================================================
    l.engagement_label,
    l.is_engagement_bait,
    l.is_harmful_bait,
    l.bait_type,
    l.label_confidence,
    l.media_context_used,
    l.label_reason,
    l.labeled_by,
    l.labeled_at

FROM tweets t

LEFT JOIN users u
    ON t.author_id = u.author_id

LEFT JOIN media_summary ms
    ON t.tweet_id = ms.tweet_id

INNER JOIN tweet_labels l
    ON t.tweet_id = l.tweet_id

WHERE t.eligible_for_labeling = TRUE;

-- Verifying correct full table creation

SELECT COUNT(*) AS rows
FROM tweet_modeling_dataset;

SELECT engagement_label, COUNT(*)
FROM tweet_modeling_dataset
GROUP BY engagement_label
ORDER BY COUNT(*) DESC;

SELECT bait_type, COUNT(*)
FROM tweet_modeling_dataset
GROUP BY bait_type
ORDER BY COUNT(*) DESC;

SELECT *
FROM tweet_modeling_dataset
LIMIT 10;