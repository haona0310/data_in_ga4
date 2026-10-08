WITH events AS (
  -- Tầng 1: mỗi event một dòng, lấy các cột và tham số cần dùng
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')        AS ga_session_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec') AS engagement_time_msec,
    event_name,
    device.category AS device_category
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

sessions AS (
  -- Tầng 2: mỗi phiên một dòng
  SELECT
    user_pseudo_id,
    ga_session_id,
    MIN(device_category)                   AS device_category,
    COUNT(DISTINCT device_category)        AS n_devices,
    COUNTIF(event_name = 'page_view')      AS n_pageviews,
    COALESCE(SUM(engagement_time_msec), 0) AS engagement_msec,
    LOGICAL_OR(event_name = 'purchase')    AS has_purchase
  FROM events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
)

-- Tầng 3: mỗi thiết bị một dòng
SELECT
  device_category,
  COUNT(*)                                     AS n_sessions,
  COUNT(*) / SUM(COUNT(*)) OVER ()             AS session_share,
  AVG(n_pageviews)                             AS avg_pageviews_per_session,
  AVG(engagement_msec) / 1000                  AS avg_engagement_seconds,
  SAFE_DIVIDE(COUNTIF(has_purchase), COUNT(*)) AS session_conversion_rate,
  COUNTIF(n_devices > 1)                       AS n_sessions_multi_device
FROM sessions
GROUP BY device_category
ORDER BY n_sessions DESC;

-- ket qua : 
-- device_category	n_sessions	session_share	avg_pageviews_per_session	avg_engagement_seconds	session_conversion_rate	n_sessions_multi_device
-- desktop	208942	0.5801865442660824	3.7606991413884958	69.786348958083366	0.013156761206459209	0
-- mobile	143185	0.39759364005675746	3.7385899360966794	71.444390864965868	0.013933023710584209	0
-- tablet	8002	0.02221981567716013	3.6678330417395757	65.260914896275651	0.012996750812296926	0