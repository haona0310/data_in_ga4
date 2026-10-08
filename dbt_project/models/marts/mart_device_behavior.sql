WITH sessions AS (
  -- Mỗi phiên một dòng
  SELECT
    session_key,
    MIN(device_category)                   AS device_category,
    COUNT(DISTINCT device_category)        AS n_devices,
    COUNTIF(event_name = 'page_view')      AS n_pageviews,
    COALESCE(SUM(engagement_time_msec), 0) AS engagement_msec,
    LOGICAL_OR(event_name = 'purchase')    AS has_purchase
  FROM {{ ref('stg_events') }}
  WHERE session_key IS NOT NULL
  GROUP BY session_key
)

-- Mỗi thiết bị một dòng
SELECT
  PARSE_DATE('%Y%m%d', '{{ var("start_date") }}') AS period_start,
  PARSE_DATE('%Y%m%d', '{{ var("end_date") }}')   AS period_end,
  device_category,
  COUNT(*)                                     AS n_sessions,
  COUNT(*) / SUM(COUNT(*)) OVER ()             AS session_share,
  AVG(n_pageviews)                             AS avg_pageviews_per_session,
  AVG(engagement_msec) / 1000                  AS avg_engagement_seconds,
  SAFE_DIVIDE(COUNTIF(has_purchase), COUNT(*)) AS session_conversion_rate,
  COUNTIF(n_devices > 1)                       AS n_sessions_multi_device
FROM sessions
GROUP BY device_category