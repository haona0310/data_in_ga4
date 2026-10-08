WITH events AS (
  -- Chỉ lấy 4 loại event của phễu, từ mốc funnel_start_date
  SELECT
    session_key,
    event_name
  FROM {{ ref('stg_events') }}
  WHERE event_date >= PARSE_DATE('%Y%m%d', '{{ var("funnel_start_date") }}')
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
),

sessions AS (
  -- Mỗi phiên một dòng, kèm 4 cờ cho biết phiên có xảy ra từng bước không
  SELECT
    session_key,
    LOGICAL_OR(event_name = 'view_item')      AS has_view_item,
    LOGICAL_OR(event_name = 'add_to_cart')    AS has_add_to_cart,
    LOGICAL_OR(event_name = 'begin_checkout') AS has_begin_checkout,
    LOGICAL_OR(event_name = 'purchase')       AS has_purchase
  FROM events
  WHERE session_key IS NOT NULL
  GROUP BY session_key
)

-- Gộp toàn bộ phiên thành 1 dòng
SELECT
  PARSE_DATE('%Y%m%d', '{{ var("funnel_start_date") }}') AS period_start,
  PARSE_DATE('%Y%m%d', '{{ var("end_date") }}')          AS period_end,

  COUNTIF(has_view_item)      AS n_sessions_view_item,
  COUNTIF(has_add_to_cart)    AS n_sessions_add_to_cart,
  COUNTIF(has_begin_checkout) AS n_sessions_begin_checkout,
  COUNTIF(has_purchase)       AS n_sessions_purchase,

  SAFE_DIVIDE(COUNTIF(has_add_to_cart),    COUNTIF(has_view_item))      AS rate_view_to_cart,
  SAFE_DIVIDE(COUNTIF(has_begin_checkout), COUNTIF(has_add_to_cart))    AS rate_cart_to_checkout,
  SAFE_DIVIDE(COUNTIF(has_purchase),       COUNTIF(has_begin_checkout)) AS rate_checkout_to_purchase,
  SAFE_DIVIDE(COUNTIF(has_purchase),       COUNTIF(has_view_item))      AS rate_view_to_purchase,

  COUNTIF(has_purchase AND NOT has_add_to_cart) AS n_sessions_purchase_without_cart
FROM sessions