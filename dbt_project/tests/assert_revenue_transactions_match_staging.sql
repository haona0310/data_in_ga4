WITH mart AS (
  SELECT SUM(n_transactions) AS n FROM {{ ref('mart_revenue_by_source') }}
),
stg AS (
  SELECT COUNT(DISTINCT transaction_id) AS n
  FROM {{ ref('stg_events') }}
  WHERE event_name = 'purchase'
    AND NOT is_placeholder_txn
)
SELECT mart.n AS mart_transactions, stg.n AS stg_transactions
FROM mart CROSS JOIN stg
WHERE mart.n != stg.n