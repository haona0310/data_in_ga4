-- Kiểm tra: toàn bộ event của phiên 8144402352 ngày 01/12/2020 (một phiên có mua hàng).
-- Kết quả: purchase bị ghi 2 lần (cùng transaction_id, cùng $55) do tải lại trang xác nhận;
--          add_shipping_info có timestamp trước begin_checkout; source ở cấp event trống hoặc <Other>.
SELECT
  TIMESTAMP_MICROS(event_timestamp) AS event_time,
  user_pseudo_id,
  event_name,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_title,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source')     AS source,
  device.category                   AS device,
  ecommerce.transaction_id          AS transaction_id,
  ecommerce.purchase_revenue_in_usd AS revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX = '20201201'
  AND (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') = 8144402352
ORDER BY event_timestamp;

-- Kết quả đã ghi nhận:
-- - Một phiên, desktop, khoảng 15 phút (09:25 → 09:40 UTC), có first_visit.
-- - 2 event purchase $55.0 lúc 09:38:56 và 09:40:13, mỗi lần đi sau một page_view trang
--   "Checkout Confirmation", cùng transaction_id.
-- - add_shipping_info có timestamp sớm hơn begin_checkout; begin_checkout bị ghi 2 lần cách nhau dưới 0,1 giây.
-- - source ở cấp event trống hoặc <Other>.


-- Kết quả query:
-- event_time	user_pseudo_id	event_name	page_title	source	device	transaction_id	revenue
-- 2020-12-01 09:25:06.389678 UTC	1026932.0858862293	session_start	Home		desktop		
-- 2020-12-01 09:25:06.389678 UTC	1026932.0858862293	page_view	Home	<Other>	desktop		
-- 2020-12-01 09:25:06.389678 UTC	1026932.0858862293	first_visit	Home		desktop		
-- 2020-12-01 09:25:11.412398 UTC	1026932.0858862293	view_promotion	Home	<Other>	desktop	(not set)	
-- 2020-12-01 09:26:03.973169 UTC	1026932.0858862293	scroll	Home	<Other>	desktop		
-- 2020-12-01 09:26:26.831938 UTC	1026932.0858862293	user_engagement	Home	<Other>	desktop		
-- 2020-12-01 09:26:32.331188 UTC	1026932.0858862293	page_view	Google | Shop by Brand | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:27:21.432144 UTC	1026932.0858862293	user_engagement	Google | Shop by Brand | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:27:26.879788 UTC	1026932.0858862293	view_search_results	Store search results		desktop		
-- 2020-12-01 09:27:26.879788 UTC	1026932.0858862293	page_view	Store search results		desktop		
-- 2020-12-01 09:27:40.857881 UTC	1026932.0858862293	scroll	Store search results		desktop		
-- 2020-12-01 09:27:40.857881 UTC	1026932.0858862293	view_item	Store search results		desktop	(not set)	
-- 2020-12-01 09:27:56.650618 UTC	1026932.0858862293	view_item	Store search results	<Other>	desktop	(not set)	
-- 2020-12-01 09:28:11.786144 UTC	1026932.0858862293	user_engagement	Store search results	<Other>	desktop		
-- 2020-12-01 09:28:17.228203 UTC	1026932.0858862293	scroll	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:28:17.228203 UTC	1026932.0858862293	page_view	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:28:31.649088 UTC	1026932.0858862293	view_item	Google | Shop by Brand | Google Merchandise Store		desktop	(not set)	
-- 2020-12-01 09:28:39.562146 UTC	1026932.0858862293	add_to_cart	Google | Shop by Brand | Google Merchandise Store		desktop	(not set)	
-- 2020-12-01 09:28:46.330165 UTC	1026932.0858862293	user_engagement	Google | Shop by Brand | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:28:52.548256 UTC	1026932.0858862293	page_view	Google Sherpa Zip Hoodie Navy		desktop		
-- 2020-12-01 09:28:52.548256 UTC	1026932.0858862293	view_item	Google Sherpa Zip Hoodie Navy		desktop	(not set)	
-- 2020-12-01 09:29:15.609790 UTC	1026932.0858862293	user_engagement	Google Sherpa Zip Hoodie Navy	<Other>	desktop		
-- 2020-12-01 09:29:21.096189 UTC	1026932.0858862293	page_view	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:29:21.096189 UTC	1026932.0858862293	scroll	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:29:35.978957 UTC	1026932.0858862293	user_engagement	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:29:35.978957 UTC	1026932.0858862293	view_item	Google | Shop by Brand | Google Merchandise Store		desktop	(not set)	
-- 2020-12-01 09:29:41.469398 UTC	1026932.0858862293	user_engagement	Google Sherpa Zip Hoodie Charcoal		desktop		
-- 2020-12-01 09:29:41.469398 UTC	1026932.0858862293	page_view	Google Sherpa Zip Hoodie Charcoal		desktop		
-- 2020-12-01 09:29:41.469398 UTC	1026932.0858862293	view_item	Google Sherpa Zip Hoodie Charcoal		desktop	(not set)	
-- 2020-12-01 09:29:46.886703 UTC	1026932.0858862293	page_view	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:29:46.886703 UTC	1026932.0858862293	scroll	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:30:24.502118 UTC	1026932.0858862293	user_engagement	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:30:24.502118 UTC	1026932.0858862293	view_item	Google | Shop by Brand | Google Merchandise Store		desktop	(not set)	
-- 2020-12-01 09:30:30.719617 UTC	1026932.0858862293	page_view	Google Badge Heavyweight Pullover Black	<Other>	desktop		
-- 2020-12-01 09:30:30.864276 UTC	1026932.0858862293	user_engagement	Google Badge Heavyweight Pullover Black	<Other>	desktop		
-- 2020-12-01 09:30:36.245661 UTC	1026932.0858862293	scroll	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:30:36.245661 UTC	1026932.0858862293	page_view	Google | Shop by Brand | Google Merchandise Store		desktop		
-- 2020-12-01 09:31:40.077606 UTC	1026932.0858862293	user_engagement	Google | Shop by Brand | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:31:45.690148 UTC	1026932.0858862293	page_view	Home	<Other>	desktop		
-- 2020-12-01 09:32:33.763790 UTC	1026932.0858862293	scroll	Home	<Other>	desktop		
-- 2020-12-01 09:32:52.572311 UTC	1026932.0858862293	view_item	Home		desktop	(not set)	
-- 2020-12-01 09:32:53.266681 UTC	1026932.0858862293	user_engagement	Home	<Other>	desktop		
-- 2020-12-01 09:32:59.484738 UTC	1026932.0858862293	view_item	Google Sherpa Zip Hoodie Navy		desktop	(not set)	
-- 2020-12-01 09:32:59.484738 UTC	1026932.0858862293	page_view	Google Sherpa Zip Hoodie Navy		desktop		
-- 2020-12-01 09:33:10.902238 UTC	1026932.0858862293	user_engagement	Google Sherpa Zip Hoodie Navy	<Other>	desktop		
-- 2020-12-01 09:33:16.392954 UTC	1026932.0858862293	page_view	New | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:33:28.161459 UTC	1026932.0858862293	user_engagement	New | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:33:33.676299 UTC	1026932.0858862293	page_view	Drinkware | Lifestyle | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:33:51.315339 UTC	1026932.0858862293	scroll	Drinkware | Lifestyle | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:34:05.890418 UTC	1026932.0858862293	user_engagement	Drinkware | Lifestyle | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:34:11.279372 UTC	1026932.0858862293	page_view	Sale | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:34:24.609515 UTC	1026932.0858862293	view_item	Sale | Google Merchandise Store		desktop	(not set)	
-- 2020-12-01 09:34:28.211451 UTC	1026932.0858862293	page_view	Google Men's Discovery Lt. Rain Shell	<Other>	desktop		
-- 2020-12-01 09:34:29.346035 UTC	1026932.0858862293	user_engagement	Google Men's Discovery Lt. Rain Shell	<Other>	desktop		
-- 2020-12-01 09:35:10.669233 UTC	1026932.0858862293	view_item	Sale | Google Merchandise Store		desktop	(not set)	
-- 2020-12-01 09:35:12.023789 UTC	1026932.0858862293	user_engagement	Google Mens Microfleece Jacket Black		desktop		
-- 2020-12-01 09:35:12.023789 UTC	1026932.0858862293	page_view	Google Mens Microfleece Jacket Black		desktop		
-- 2020-12-01 09:35:35.534572 UTC	1026932.0858862293	scroll	Sale | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:35:39.377938 UTC	1026932.0858862293	user_engagement	Sale | Google Merchandise Store	<Other>	desktop		
-- 2020-12-01 09:35:44.793498 UTC	1026932.0858862293	scroll	Shopping Cart		desktop		
-- 2020-12-01 09:35:44.793498 UTC	1026932.0858862293	page_view	Shopping Cart		desktop		
-- 2020-12-01 09:35:51.496984 UTC	1026932.0858862293	user_engagement	Shopping Cart	<Other>	desktop		
-- 2020-12-01 09:35:56.874507 UTC	1026932.0858862293	scroll	The Google Merchandise Store - Log In		desktop		
-- 2020-12-01 09:35:56.874507 UTC	1026932.0858862293	page_view	The Google Merchandise Store - Log In		desktop		
-- 2020-12-01 09:35:57.520148 UTC	1026932.0858862293	user_engagement	The Google Merchandise Store - Log In	<Other>	desktop		
-- 2020-12-01 09:36:03.349003 UTC	1026932.0858862293	page_view	The Google Merchandise Store - Log In		desktop		
-- 2020-12-01 09:36:03.349003 UTC	1026932.0858862293	scroll	The Google Merchandise Store - Log In		desktop		
-- 2020-12-01 09:36:03.349003 UTC	1026932.0858862293	user_engagement	The Google Merchandise Store - Log In		desktop		
-- 2020-12-01 09:36:08.516282 UTC	1026932.0858862293	page_view	Home		desktop		
-- 2020-12-01 09:36:08.516282 UTC	1026932.0858862293	user_engagement	Home		desktop		
-- 2020-12-01 09:36:08.516282 UTC	1026932.0858862293	view_promotion	Home		desktop	(not set)	
-- 2020-12-01 09:36:13.864874 UTC	1026932.0858862293	page_view	Shopping Cart	<Other>	desktop		
-- 2020-12-01 09:36:20.062169 UTC	1026932.0858862293	scroll	Shopping Cart	<Other>	desktop		
-- 2020-12-01 09:36:32.054313 UTC	1026932.0858862293	user_engagement	Shopping Cart	<Other>	desktop		
-- 2020-12-01 09:36:32.465601 UTC	1026932.0858862293	page_view	Checkout Your Information		desktop		
-- 2020-12-01 09:36:32.465601 UTC	1026932.0858862293	add_shipping_info	Checkout Your Information		desktop	(not set)	
-- 2020-12-01 09:36:32.465767 UTC	1026932.0858862293	begin_checkout	Checkout Your Information		desktop	(not set)	
-- 2020-12-01 09:36:32.553894 UTC	1026932.0858862293	begin_checkout	Checkout Your Information		desktop	(not set)	
-- 2020-12-01 09:37:28.074140 UTC	1026932.0858862293	scroll	Checkout Your Information		desktop		
-- 2020-12-01 09:37:54.730932 UTC	1026932.0858862293	user_engagement	Checkout Your Information		desktop		
-- 2020-12-01 09:38:00.025670 UTC	1026932.0858862293	add_payment_info	Payment Method		desktop	(not set)	
-- 2020-12-01 09:38:00.025670 UTC	1026932.0858862293	page_view	Payment Method		desktop		
-- 2020-12-01 09:38:43.042860 UTC	1026932.0858862293	user_engagement	Payment Method		desktop		
-- 2020-12-01 09:38:43.042860 UTC	1026932.0858862293	scroll	Payment Method		desktop		
-- 2020-12-01 09:38:48.873408 UTC	1026932.0858862293	page_view	Checkout Review		desktop		
-- 2020-12-01 09:38:56.194634 UTC	1026932.0858862293	scroll	Checkout Review		desktop		
-- 2020-12-01 09:38:56.194634 UTC	1026932.0858862293	user_engagement	Checkout Review		desktop		
-- 2020-12-01 09:38:56.636123 UTC	1026932.0858862293	page_view	Checkout Confirmation		desktop		
-- 2020-12-01 09:38:56.636655 UTC	1026932.0858862293	purchase	Checkout Confirmation		desktop	339943	55.0
-- 2020-12-01 09:39:06.028117 UTC	1026932.0858862293	scroll	Checkout Confirmation		desktop		
-- 2020-12-01 09:39:08.386249 UTC	1026932.0858862293	user_engagement	Checkout Confirmation		desktop		
-- 2020-12-01 09:40:13.649794 UTC	1026932.0858862293	page_view	Checkout Confirmation		desktop		
-- 2020-12-01 09:40:13.649978 UTC	1026932.0858862293	purchase	Checkout Confirmation		desktop	339943	55.0
-- 2020-12-01 09:40:23.747215 UTC	1026932.0858862293	scroll	Checkout Confirmation		desktop		
-- 2020-12-01 09:40:23.800993 UTC	1026932.0858862293	user_engagement	Checkout Confirmation		desktop		
-- 2020-12-01 09:40:29.367049 UTC	1026932.0858862293	scroll	The Google Merchandise Store - My Account		desktop		
-- 2020-12-01 09:40:29.367049 UTC	1026932.0858862293	page_view	The Google Merchandise Store - My Account		desktop		
-- 2020-12-01 09:40:32.136831 UTC	1026932.0858862293	user_engagement	The Google Merchandise Store - My Account	<Other>	desktop		
