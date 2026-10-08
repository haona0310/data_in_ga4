WITH user_events AS(
    SELECT 
        user_pseudo_id,
        traffic_source.medium as medium,
        ROW_NUMBER() OVER(
            PARTITION BY user_pseudo_id
            ORDER BY event_timestamp, traffic_source.medium
        ) as rn 
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

user_channel AS (
    SELECT
        user_pseudo_id,
        CASE WHEN medium is null or medium in ('<Other>', '(data deleted)') THEN 'unknown'
            WHEN medium = '(none)' THEN 'direct' 
            ELSE medium 
        END as channel
    FROM user_events
    WHERE rn = 1 
),

purchases AS (
    SELECT 
        user_pseudo_id,
        ecommerce.transaction_id as transaction_id,
        ecommerce.purchase_revenue_in_usd as revenue,
        ROW_NUMBER() OVER(  
            PARTITION BY ecommerce.transaction_id 
            ORDER BY event_timestamp
        ) AS rn 
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
    AND (ecommerce.transaction_id is not null AND ecommerce.transaction_id <> '(not set)')
),

user_purchases AS (
  -- Mỗi user một dòng: số giao dịch, doanh thu, số giao dịch có doanh thu > 0
  SELECT
    user_pseudo_id,
    COUNT(*) AS n_transactions,
    SUM(purchases.revenue) AS revenue,
    COUNTIF(purchases.revenue > 0) AS n_transactions_nonzero 

  FROM purchases
  WHERE rn = 1
  GROUP BY user_pseudo_id
)

SELECT
  c.channel,
  COUNT(*)                                                 AS n_users,
  COUNTIF(p.n_transactions > 0)                            AS n_buyers,
  SAFE_DIVIDE(COUNTIF(p.n_transactions > 0), COUNT(*))     AS user_conversion_rate,
  SUM(p.n_transactions)                                    AS n_transactions,
  SUM(p.revenue)                                           AS revenue,
  SAFE_DIVIDE(SUM(p.revenue), SUM(p.n_transactions_nonzero)) AS aov
FROM user_channel AS c
LEFT JOIN user_purchases AS p
  USING (user_pseudo_id)
GROUP BY c.channel
ORDER BY revenue DESC;



-- ket qua:
-- channel	n_users	n_buyers	user_conversion_rate	n_transactions	revenue	aov
-- organic	101742	1330	0.013072280867291777	1613	106981.0	66.324240545567264
-- direct	64109	844	0.013165078226146095	1017	71535.0	70.339233038348084
-- unknown	50001	743	0.014859702805943882	903	64161.0	71.0531561461794
-- referral	40020	604	0.015092453773113444	713	49409.0	69.29733520336606
-- cpc	14282	181	0.012673295056714745	205	15554.0	75.873170731707319