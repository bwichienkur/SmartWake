-- Pulse ClickHouse Analytics Schema
-- Run against ClickHouse for production OLAP reporting

CREATE DATABASE IF NOT EXISTS pulse_analytics;

-- Primary event fact table (billions of rows, partitioned by month)
CREATE TABLE IF NOT EXISTS pulse_analytics.events (
    event_id UUID,
    workspace_id UUID,
    event_type LowCardinality(String),
    contact_id Nullable(UUID),
    campaign_id Nullable(UUID),
    automation_id Nullable(UUID),
    email Nullable(String),
    domain LowCardinality(Nullable(String)),
    isp LowCardinality(Nullable(String)),
    device LowCardinality(Nullable(String)),
    client LowCardinality(Nullable(String)),
    country LowCardinality(Nullable(String)),
    region LowCardinality(Nullable(String)),
    utm_source Nullable(String),
    utm_medium Nullable(String),
    utm_campaign Nullable(String),
    revenue Nullable(Decimal64(4)),
    properties_json Nullable(String),
    occurred_at DateTime64(3, 'UTC'),
    ingested_at DateTime64(3, 'UTC') DEFAULT now64(3)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(occurred_at)
ORDER BY (workspace_id, event_type, occurred_at, event_id)
TTL occurred_at + INTERVAL 3 YEAR;

-- Daily campaign metrics materialized view
CREATE TABLE IF NOT EXISTS pulse_analytics.campaign_daily_metrics (
    workspace_id UUID,
    campaign_id UUID,
    date Date,
    sent UInt64 DEFAULT 0,
    delivered UInt64 DEFAULT 0,
    opened UInt64 DEFAULT 0,
    unique_opened UInt64 DEFAULT 0,
    clicked UInt64 DEFAULT 0,
    unique_clicked UInt64 DEFAULT 0,
    bounced UInt64 DEFAULT 0,
    soft_bounced UInt64 DEFAULT 0,
    hard_bounced UInt64 DEFAULT 0,
    unsubscribed UInt64 DEFAULT 0,
    complained UInt64 DEFAULT 0,
    revenue Decimal64(4) DEFAULT 0,
    updated_at DateTime64(3, 'UTC') DEFAULT now64(3)
) ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (workspace_id, campaign_id, date);

CREATE MATERIALIZED VIEW IF NOT EXISTS pulse_analytics.campaign_daily_metrics_mv
TO pulse_analytics.campaign_daily_metrics AS
SELECT
    workspace_id,
    campaign_id,
    toDate(occurred_at) AS date,
    countIf(event_type LIKE '%sent%') AS sent,
    countIf(event_type LIKE '%delivered%') AS delivered,
    countIf(event_type LIKE '%opened%') AS opened,
    uniqExactIf(contact_id, event_type LIKE '%opened%') AS unique_opened,
    countIf(event_type LIKE '%clicked%') AS clicked,
    uniqExactIf(contact_id, event_type LIKE '%clicked%') AS unique_clicked,
    countIf(event_type LIKE '%bounced%') AS bounced,
    countIf(event_type LIKE '%soft_bounced%') AS soft_bounced,
    countIf(event_type LIKE '%hard_bounced%') AS hard_bounced,
    countIf(event_type LIKE '%unsubscribed%') AS unsubscribed,
    countIf(event_type LIKE '%complained%') AS complained,
    sum(revenue) AS revenue
FROM pulse_analytics.events
WHERE campaign_id IS NOT NULL
GROUP BY workspace_id, campaign_id, date;

-- Deliverability by domain/ISP
CREATE TABLE IF NOT EXISTS pulse_analytics.deliverability_daily (
    workspace_id UUID,
    date Date,
    sending_domain LowCardinality(String),
    isp LowCardinality(String),
    sent UInt64 DEFAULT 0,
    delivered UInt64 DEFAULT 0,
    bounced UInt64 DEFAULT 0,
    complained UInt64 DEFAULT 0,
    updated_at DateTime64(3, 'UTC') DEFAULT now64(3)
) ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (workspace_id, sending_domain, isp, date);

-- Automation path analysis
CREATE TABLE IF NOT EXISTS pulse_analytics.automation_step_events (
    workspace_id UUID,
    automation_id UUID,
    enrollment_id UUID,
    contact_id UUID,
    step_id String,
    step_type LowCardinality(String),
    action LowCardinality(String),
    reason Nullable(String),
    occurred_at DateTime64(3, 'UTC')
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(occurred_at)
ORDER BY (workspace_id, automation_id, occurred_at);

-- Contact engagement scores (updated periodically)
CREATE TABLE IF NOT EXISTS pulse_analytics.contact_engagement_daily (
    workspace_id UUID,
    contact_id UUID,
    date Date,
    emails_sent UInt32 DEFAULT 0,
    emails_opened UInt32 DEFAULT 0,
    emails_clicked UInt32 DEFAULT 0,
    revenue Decimal64(4) DEFAULT 0,
    engagement_score Float32 DEFAULT 0
) ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (workspace_id, contact_id, date);

-- Attribution events (multi-touch)
CREATE TABLE IF NOT EXISTS pulse_analytics.attribution_events (
    workspace_id UUID,
    contact_id UUID,
    order_id Nullable(String),
    touchpoint_type LowCardinality(String),
    touchpoint_id Nullable(UUID),
    utm_source Nullable(String),
    utm_medium Nullable(String),
    utm_campaign Nullable(String),
    revenue Decimal64(4),
    attribution_model LowCardinality(String),
    weight Float32,
    occurred_at DateTime64(3, 'UTC')
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(occurred_at)
ORDER BY (workspace_id, contact_id, occurred_at);
