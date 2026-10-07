-- Kiểm tra: các key trong event_params và trường kiểu dữ liệu chứa giá trị (ngày 01/12/2020).
-- Kết quả: ga_session_id, ga_session_number kiểu int; source/medium/campaign kiểu string, chỉ có trên ~25k/71,8k dòng;
--          session_engaged và value lẫn kiểu → khi lấy giá trị phải gộp các trường.
SELECT
  ep.key,
  COUNT(*)                                   AS n_rows,
  COUNTIF(ep.value.string_value IS NOT NULL) AS n_string,
  COUNTIF(ep.value.int_value    IS NOT NULL) AS n_int,
  COUNTIF(ep.value.float_value  IS NOT NULL) AS n_float,
  COUNTIF(ep.value.double_value IS NOT NULL) AS n_double
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(event_params) AS ep
WHERE _TABLE_SUFFIX = '20201201'
GROUP BY ep.key
ORDER BY n_rows DESC;

-- Kết quả đã ghi nhận:
-- - ga_session_id, ga_session_number: kiểu int.
-- - source, medium, campaign: kiểu string, chỉ có trên khoảng 25 nghìn / 71,8 nghìn dòng.
-- - session_engaged lẫn kiểu: string 63589, int 4162.
-- - value lẫn kiểu: int 41, double 56.
-- - transaction_id có 97 dòng, trong khi ngày 01/12 có 107 event purchase (theo query 02).


-- Kết quả query:
-- key	n_rows	n_string	n_int	n_float	n_double
-- ga_session_id	71804	0	71804	0	0
-- ga_session_number	71804	0	71804	0	0
-- page_location	71804	71804	0	0	0
-- page_title	71443	71443	0	0	0
-- engaged_session_event	69253	0	69253	0	0
-- session_engaged	67751	63589	4162	0	0
-- debug_mode	63584	0	63584	0	0
-- all_data	63584	0	0	0	0
-- clean_event	63581	63581	0	0	0
-- page_referrer	51881	19257	0	0	0
-- engagement_time_msec	40462	0	40462	0	0
-- campaign	25016	25016	0	0	0
-- medium	25016	25016	0	0	0
-- source	24731	24731	0	0	0
-- percent_scrolled	8629	0	8629	0	0
-- term	4860	4860	0	0	0
-- entrances	4526	0	4526	0	0
-- gclid	1254	0	0	0	0
-- gclsrc	1193	0	0	0	0
-- currency	756	756	0	0	0
-- search_term	339	339	0	0	0
-- unique_search_term	275	0	275	0	0
-- value	97	0	41	0	56
-- payment_type	97	97	0	0	0
-- transaction_id	97	97	0	0	0
-- tax	97	0	3	0	94
-- shipping_tier	96	96	0	0	0
-- promotion_name	81	81	0	0	0
-- coupon	73	73	0	0	0
-- dclid	45	0	0	0	0
-- link_domain	16	16	0	0	0
-- outbound	16	16	0	0	0
-- link_url	16	16	0	0	0