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
)

SELECT 
    channel, 
    COUNT(*) AS n_users,
    COUNT(*) / SUM(COUNT(*)) OVER() AS user_share
FROM user_channel
GROUP BY channel
ORDER BY n_users DESC 


-- channel	n_users	user_share
-- organic	101742	0.37660741651058283
-- direct	64109	0.23730538877825241
-- unknown	50001	0.18508332284548812
-- referral	40020	0.14813772885095167
-- cpc	14282	0.052866143014724934