## Tổng hợp quyết định thiết kế (nguyên liệu cho README mục 6)

### Khoảng thời gian và phễu
1. add_to_cart thiếu tracking 01/11–25/11/2020 (gần như = 0 trong khi purchase vẫn có)
   → mart_funnel chỉ dùng dữ liệu từ 26/11/2020; hai mart còn lại dùng toàn bộ giai đoạn.
   Mỗi mart có cột period_start, period_end.
2. Thứ tự timestamp không đáng tin (add_shipping_info trước begin_checkout; nhiều event trùng timestamp)
   → phễu tính theo "phiên có xảy ra bước X", không xét thứ tự.
3. Trong giai đoạn 26/11–31/01: 874/3626 phiên mua hàng (24,1%) không có add_to_cart trong cùng phiên.
   257 phiên có add_to_cart ở phiên khác của cùng user; 617 phiên (17,0% phiên mua hàng) không có
   add_to_cart ở bất kỳ phiên nào (thiếu tracking, khác thiết bị, hoặc thêm giỏ trước 26/11).
   → rate_view_to_cart có thể bị đánh giá thấp, rate_cart_to_checkout có thể bị đánh giá cao;
     dùng rate_view_to_purchase làm chỉ số chính; giữ cột n_sessions_purchase_without_cart trong mart.

### Giao dịch và doanh thu
4. Purchase bị ghi trùng khi tải lại trang xác nhận (cùng transaction_id, cùng doanh thu)
   → loại trùng bằng ROW_NUMBER(), giữ event đầu tiên của mỗi transaction_id.
5. Mã giữ chỗ: (not set) 883 event, NULL 23 event; tổng 906/5692 event (15,9%),
   31817/362165 doanh thu thô (8,8%) → loại khỏi chỉ số doanh thu, giữ trong phễu; cờ is_placeholder_txn.
6. Khoảng 20 mã giao dịch hợp lệ có doanh thu khác nhau giữa các bản ghi → giữ event đầu tiên.
   Tổng doanh thu sau làm sạch: 307640 (so với 308200 nếu lấy MAX, chênh 560).
7. 450 event purchase có doanh thu 0, tất cả thuộc nhóm mã giữ chỗ hoặc bản ghi trùng;
   sau khi làm sạch không còn giao dịch $0 (kiểm tra: revenue / aov = n_transactions).

### Nguồn truy cập
8. traffic_source không cố định theo user: 42260/270154 user (15,6%) có nhiều hơn 1 cặp (medium, source)
   → gán kênh từ event sớm nhất của user (phá hòa theo medium để kết quả lặp lại được).
9. Phân tích theo medium (ít bị làm mờ hơn source). <Other>, (data deleted), NULL → 'unknown';
   (none) → 'direct'. Nhóm unknown chiếm 18,5% user và 20,9% doanh thu.
10. Self-referral: referral / shop.googlemerchandisestore.com có 26065 user → dấu hiệu cấu hình
    tracking chưa chuẩn; giữ trong nhóm referral.

### Thiết bị và hành vi phiên
11. device.category sạch (chỉ desktop / mobile / tablet). 4182 user (1,5%) có nhiều thiết bị,
    nhưng 0 phiên có nhiều thiết bị → phân tích thiết bị theo phiên.
12. Phiên không có event mang engagement_time_msec được tính là 0 giây (COALESCE),
    tránh thổi phồng trung bình do AVG bỏ qua NULL.

### Kiểu dữ liệu
13. event_params lẫn kiểu: session_engaged (string/int), value (int/double) → gộp các trường khi lấy giá trị.

### Lưu ý khi diễn giải (đưa vào mục Hạn chế và prompt LLM)
14. Chênh lệch giữa các nhóm rất nhỏ: tỷ lệ chuyển đổi theo kênh 1,27%–1,51%, theo thiết bị 1,30%–1,39%.
    Không kết luận nhóm nào tốt hơn rõ rệt khi chưa làm kiểm định thống kê.
    