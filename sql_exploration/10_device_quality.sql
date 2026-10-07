-- Kiểm tra: phân bố user, event, purchase theo loại thiết bị.
-- Kết quả: chỉ có desktop / mobile / tablet, không có giá trị bị làm mờ.
SELECT
  device.category                   AS device_category,
  COUNT(DISTINCT user_pseudo_id)    AS n_users,
  COUNT(*)                          AS n_events,
  COUNTIF(event_name = 'purchase')  AS n_purchase_events,
  COUNT(*) / SUM(COUNT(*)) OVER ()  AS event_share
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY device_category
ORDER BY n_users DESC;

-- Kết quả đã ghi nhận:
-- device_category	n_users	n_events	n_purchase_events
-- desktop	158917	2498330	3226
-- mobile	109195	1704069	2355
-- tablet	6250	93185	111
--
-- Kiểm tra:  n_purchase_events = 5692.
