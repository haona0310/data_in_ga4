WITH user_events AS (
  -- Đánh số event của mỗi user theo thời gian
  SELECT
    user_pseudo_id,
    traffic_channel,
    ROW_NUMBER() OVER (
      PARTITION BY user_pseudo_id
      ORDER BY event_timestamp, traffic_medium
    ) AS rn
  FROM {{ ref('stg_events') }}
),

user_channel AS (
  -- Mỗi user một dòng: kênh từ event sớm nhất
  SELECT
    user_pseudo_id,
    traffic_channel AS channel
  FROM user_events
  WHERE rn = 1
),

purchases AS (
  -- Event purchase hợp lệ, đánh số trong từng transaction_id để loại trùng
  SELECT
    user_pseudo_id,
    transaction_id,
    purchase_revenue_usd AS revenue,
    ROW_NUMBER() OVER (
      PARTITION BY transaction_id
      ORDER BY event_timestamp, purchase_revenue_usd
    ) AS rn
  FROM {{ ref('stg_events') }}
  WHERE event_name = 'purchase'
    AND NOT is_placeholder_txn
),

user_purchases AS (
  -- Mỗi user một dòng: số giao dịch, doanh thu
  SELECT
    user_pseudo_id,
    COUNT(*)             AS n_transactions,
    SUM(revenue)         AS revenue,
    COUNTIF(revenue > 0) AS n_transactions_nonzero
  FROM purchases
  WHERE rn = 1
  GROUP BY user_pseudo_id
)

SELECT
  PARSE_DATE('%Y%m%d', '{{ var("start_date") }}') AS period_start,
  PARSE_DATE('%Y%m%d', '{{ var("end_date") }}')   AS period_end,
  c.channel,
  COUNT(*)                                                   AS n_users,
  COUNTIF(p.n_transactions > 0)                              AS n_buyers,
  SAFE_DIVIDE(COUNTIF(p.n_transactions > 0), COUNT(*))       AS user_conversion_rate,
  SUM(p.n_transactions)                                      AS n_transactions,
  SUM(p.revenue)                                             AS revenue,
  SUM(p.revenue) / SUM(SUM(p.revenue)) OVER ()               AS revenue_share,
  SAFE_DIVIDE(SUM(p.revenue), SUM(p.n_transactions_nonzero)) AS aov
FROM user_channel AS c
LEFT JOIN user_purchases AS p
  USING (user_pseudo_id)
GROUP BY c.channel