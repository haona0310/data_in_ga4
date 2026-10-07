-- Kiểm tra: tổng hợp chất lượng event purchase, toàn bộ giai đoạn.
-- Kết quả: 906/5692 event (15,9%) có mã giữ chỗ, chiếm 31817/362165 (8,8%) doanh thu thô;
--          450 purchase có doanh thu 0.
WITH p AS (
  SELECT
    ecommerce.transaction_id          AS txn,
    ecommerce.purchase_revenue_in_usd AS rev
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
)
SELECT
  COUNT(*)                   AS n_events,
  SUM(rev)                   AS revenue_raw,
  COUNTIF(txn = '(not set)') AS n_not_set,
  COUNTIF(txn IS NULL)       AS n_null,
  COUNTIF(txn = '')          AS n_empty,
  SUM(IF(txn IS NULL OR txn IN ('(not set)', ''), rev, 0)) AS revenue_placeholder,
  COUNTIF(rev = 0)           AS n_zero_revenue,
  COUNTIF(rev IS NULL)       AS n_null_revenue
FROM p;

-- Kết quả đã ghi nhận:
-- n_events	revenue_raw	n_not_set	n_null	n_empty	revenue_placeholder	n_zero_revenue	n_null_revenue
-- 5692	362165.0	883	23	0	31817.0	450	0
