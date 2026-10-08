SELECT *
FROM {{ ref('mart_device_behavior') }}
WHERE n_sessions_multi_device > 0
