-- Kiểm tra: phân bố user theo (medium, source) của traffic_source.
-- Kết quả: nhiều nhóm <Other> / (data deleted); medium ít bị làm mờ hơn source.
--          Tổng n_users qua các nhóm (333388) lớn hơn số user thật → user bị đếm ở nhiều nhóm (xem query 09).
SELECT
  traffic_source.medium AS medium,
  traffic_source.source AS source,
  COUNT(DISTINCT user_pseudo_id) AS n_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY medium, source
ORDER BY n_users DESC;

-- Kết quả đã ghi nhận (các nhóm lớn nhất):
-- medium	source	n_users
-- organic	google	103487
-- (none)	(direct)	75951
-- <Other>	<Other>	51037
-- referral	<Other>	32880
-- referral	shop.googlemerchandisestore.com	26065
-- (data deleted)	(data deleted)	17948
-- cpc	google	15527
-- organic	<Other>	10095
