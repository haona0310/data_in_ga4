Xu ly du lieu ga4\_obfuscated\_sample\_ecommerce trong bigquery-public-data tren google console 



1\. add\_to\_cart thiếu tracking 01/11–25/11/2020 (gần như = 0 trong khi purchase vẫn có)

&#x20;  → mart\_funnel chỉ dùng từ 26/11/2020.

2\. Phễu đếm theo event không giảm dần (begin\_checkout > add\_to\_cart một số ngày);

&#x20;  thứ tự timestamp không đáng tin (add\_shipping\_info trước begin\_checkout)

&#x20;  → phễu tính theo "phiên có xảy ra bước X", không theo thứ tự.

3\. purchase bị ghi trùng khi tải lại trang xác nhận (cùng transaction\_id, cùng doanh thu)

&#x20;  → loại trùng bằng ROW\_NUMBER, giữ event đầu tiên.

4\. 906/5692 event purchase (15,9%) có mã giữ chỗ ((not set): 883, NULL: 23),

&#x20;  chiếm 31817/362165 (8,8%) doanh thu thô → loại khỏi chỉ số doanh thu, giữ trong phễu.

5\. Khoảng 20 mã giao dịch hợp lệ có doanh thu khác nhau giữa các bản ghi → giữ event đầu tiên.

6\. 450 purchase có doanh thu 0 → loại khỏi AOV.

7\. Kiểu dữ liệu lẫn lộn trong event\_params: session\_engaged (string/int), value (int/double).

8\. Tham số source/medium ở cấp event phần lớn trống hoặc <Other>.

