-- Bước làm thêm kiểm tra con số 874 những id mà có purchase nhưng ko thêm vào giỏ hàng
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
    LOGICAL_OR(event_name = 'add_to_cart') AS has_add_to_cart,
    LOGICAL_OR(event_name = 'purchase')    AS has_purchase
  FROM events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),

purchase_without_cart AS (
  -- Các phiên có purchase nhưng không có add_to_cart
  SELECT user_pseudo_id, ga_session_id
  FROM sessions
  WHERE has_purchase AND NOT has_add_to_cart
),

user_cart AS (
  -- Mỗi user một dòng: user có add_to_cart ở BẤT KỲ phiên nào không
  SELECT
    user_pseudo_id,
    LOGICAL_OR(has_add_to_cart) AS user_has_cart
  FROM sessions
  GROUP BY user_pseudo_id
)

SELECT
  COUNT(*)               AS n_sessions_purchase_without_cart,
  COUNTIF(user_has_cart) AS n_cart_in_other_session,
  COUNTIF(NOT user_has_cart) AS n_no_cart_anywhere
FROM purchase_without_cart
JOIN user_cart USING (user_pseudo_id);

-- n_sessions_purchase_without_cart	n_cart_in_other_session	n_no_cart_anywhere
-- 874  257	 617