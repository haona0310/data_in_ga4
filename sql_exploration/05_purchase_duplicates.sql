-- Kiểm tra: phân bố số lần lặp của transaction_id trong event purchase.
-- Kết quả: đa số giao dịch xuất hiện 1–2 lần; có 1 mã lặp 883 lần và 1 mã lặp 23 lần → giá trị giữ chỗ.
WITH txn AS (
  SELECT
    ecommerce.transaction_id               AS transaction_id,
    COUNT(*)                               AS n_events,
    MAX(ecommerce.purchase_revenue_in_usd) AS max_purchase,
    MIN(ecommerce.purchase_revenue_in_usd) AS min_purchase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
  GROUP BY transaction_id
)
SELECT
  n_events,
  COUNT(*)                              AS n_transaction,
  COUNTIF(max_purchase != min_purchase) AS conflicting_revenue,
  SUM(max_purchase)                     AS revenue_dedup
FROM txn
GROUP BY n_events
ORDER BY n_events;

-- Kết quả đã ghi nhận:
-- n_events	n_transaction	conflicting_revenue	revenue_dedup
-- 1	4125	0	286004.0
-- 2	318	12	21515.0
-- 3	7	3	504.0
-- 4	1	0	177.0
-- 23	1	1	162.0
-- 883	1	1	998.0


-- Kiểm tra: (n_events × n_transaction) = 5692;  n_transaction = 4453.
-- Lưu ý: revenue_dedup của 2 dòng cuối là sai (MAX bỏ mất doanh thu các đơn còn lại), không cộng để tính tổng.
