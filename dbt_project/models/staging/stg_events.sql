WITH source AS (
  -- Chỉ đọc các cột cần dùng, trong khoảng ngày khai báo ở vars
  SELECT
    event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    event_params,
    device.category                   AS device_category,
    traffic_source.medium             AS traffic_medium,
    ecommerce.transaction_id          AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
  FROM {{ source('ga4', 'events') }}
  WHERE _TABLE_SUFFIX BETWEEN '{{ var("start_date") }}' AND '{{ var("end_date") }}'
),

flattened AS (
  -- Làm phẳng tham số và chuẩn hóa kiểu dữ liệu
  SELECT
    PARSE_DATE('%Y%m%d', event_date)  AS event_date,
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
    event_name,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')        AS ga_session_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec') AS engagement_time_msec,
    device_category,
    traffic_medium,
    CASE
      WHEN traffic_medium IS NULL OR traffic_medium IN ('<Other>', '(data deleted)') THEN 'unknown'
      WHEN traffic_medium = '(none)' THEN 'direct'
      ELSE traffic_medium
    END AS traffic_channel,
    transaction_id,
    purchase_revenue_usd
  FROM source
)

SELECT
  *,
  CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING)) AS session_key,
  (
    event_name = 'purchase'
    AND (transaction_id IS NULL OR transaction_id = '(not set)')
  ) AS is_placeholder_txn
FROM flattened
