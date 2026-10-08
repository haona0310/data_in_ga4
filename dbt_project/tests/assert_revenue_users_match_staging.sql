WITH mart AS (
  SELECT SUM(n_users) AS n FROM {{ ref('mart_revenue_by_source') }}
),
stg AS (
  SELECT COUNT(DISTINCT user_pseudo_id) AS n FROM {{ ref('stg_events') }}
)
SELECT mart.n AS mart_users, stg.n AS stg_users
FROM mart CROSS JOIN stg
WHERE mart.n != stg.n