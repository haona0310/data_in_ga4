WITH events AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201126' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
),

sessions AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    LOGICAL_OR(event_name = 'view_item')      AS has_view_item,
    LOGICAL_OR(event_name = 'add_to_cart')    AS has_add_to_cart,
    LOGICAL_OR(event_name = 'begin_checkout') AS has_begin_checkout,
    LOGICAL_OR(event_name = 'purchase')       AS has_purchase
  FROM events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
)

SELECT
  COUNTIF(has_view_item)      AS n_sessions_view_item,
  COUNTIF(has_add_to_cart)    AS n_sessions_add_to_cart,
  COUNTIF(has_begin_checkout) AS n_sessions_begin_checkout,
  COUNTIF(has_purchase)       AS n_sessions_purchase,
  SAFE_DIVIDE(COUNTIF(has_add_to_cart),    COUNTIF(has_view_item))      AS rate_view_to_cart,
  SAFE_DIVIDE(COUNTIF(has_begin_checkout), COUNTIF(has_add_to_cart))    AS rate_cart_to_checkout,
  SAFE_DIVIDE(COUNTIF(has_purchase),       COUNTIF(has_begin_checkout)) AS rate_checkout_to_purchase,
  SAFE_DIVIDE(COUNTIF(has_purchase), COUNTIF(has_view_item)) AS rate_view_to_purchase,
  COUNTIF(has_purchase AND NOT has_add_to_cart) AS n_sessions_purchase_without_cart
FROM sessions;

-- kết quả:
-- n_sessions_view_item	n_sessions_add_to_cart	n_sessions_begin_checkout	n_sessions_purchase	rate_view_to_cart	rate_cart_to_checkout	rate_checkout_to_purchase	rate_view_to_purchase	n_sessions_purchase_without_cart
-- 55502	14578	7433	3626	0.26265720154228678	0.5098778982027713	0.48782456612404146	0.065330979063817518	874



