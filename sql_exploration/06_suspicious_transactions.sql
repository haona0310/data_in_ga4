-- Kiểm tra: các transaction_id lặp từ 3 lần hoặc có doanh thu mâu thuẫn giữa các bản ghi.
-- Kết quả: (not set) 883 event và NULL 23 event là mã giữ chỗ; khoảng 20 mã thật có doanh thu khác nhau.
WITH txn AS (
  SELECT
    ecommerce.transaction_id               AS transaction_id,
    COUNT(*)                               AS n_events,
    MIN(ecommerce.purchase_revenue_in_usd) AS min_purchase,
    MAX(ecommerce.purchase_revenue_in_usd) AS max_purchase,
    SUM(ecommerce.purchase_revenue_in_usd) AS sum_purchase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
  GROUP BY transaction_id
)
SELECT *
FROM txn
WHERE n_events >= 3
   OR max_purchase != min_purchase
ORDER BY n_events DESC;

-- Kết quả đã ghi nhận:
-- - (not set): 883 event, min 0.0, max 998.0, tổng 30489.0.
-- - NULL: 23 event, min 13.0, max 162.0, tổng 1328.0.
-- - Các mã thật có doanh thu khác nhau, ví dụ 372598 (291.0 và 49.0), 147010 (207.0 và 29.0).
