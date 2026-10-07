-- Kiểm tra: số user có nhiều hơn 1 nguồn (medium, source) hoặc nhiều hơn 1 loại thiết bị.
-- Kết quả: 42260/270154 user (15,6%) có nhiều nguồn → traffic_source không cố định theo user;
--          4182 user (1,5%) có nhiều thiết bị.
WITH user_profile AS (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT CONCAT(traffic_source.medium, ' | ', traffic_source.source)) AS n_sources,
    COUNT(DISTINCT device.category) AS n_devices
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY user_pseudo_id
)
SELECT
  COUNT(*)               AS n_users,
  COUNTIF(n_sources > 1) AS n_users_multi_source,
  COUNTIF(n_devices > 1) AS n_users_multi_device
FROM user_profile;

-- Kết quả đã ghi nhận:
-- n_users	n_users_multi_source	n_users_multi_device
-- 270154	42260	4182
