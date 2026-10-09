## Các tầng

**Staging — `stg_events`**
Đọc dữ liệu nguồn trong khoảng ngày khai báo ở `vars`, chỉ chọn các cột cần dùng. Làm phẳng `event_params` (`ga_session_id`, `engagement_time_msec`), chuẩn hóa kiểu (DATE, TIMESTAMP), gộp nguồn truy cập thành `traffic_channel`, tạo `session_key`, gắn cờ `is_placeholder_txn`. Materialize dạng bảng để các mart không quét lại cột `event_params` từ nguồn.

**Marts**
- `mart_funnel`: phễu theo phiên từ `funnel_start_date`; cờ từng bước bằng `LOGICAL_OR`, không xét thứ tự.
- `mart_revenue_by_source`: kênh của event sớm nhất mỗi user (`ROW_NUMBER`); purchase loại mã giữ chỗ và loại trùng theo `transaction_id`; gộp giao dịch lên cấp user trước khi `LEFT JOIN` để tránh nhân dòng.
- `mart_device_behavior`: chỉ số hành vi theo phiên, kể cả purchase mang mã giữ chỗ.

**Lớp AI và kiểm chứng**
- `extract.py`: chuyển 3 mart thành 59 số liệu với key cố định (ví dụ `revenue.organic.aov`) và lưu snapshot. Verify đối chiếu với snapshot này, tức đúng dữ liệu mà LLM đã nhận.
- `generate_report.py`: gọi Gemini với output ép theo JSON schema; prompt yêu cầu gắn nhãn `[key]` ngay sau mỗi con số. Lưu bản có nhãn (cho verify) và bản đã xóa nhãn (cho người đọc).
- `verify.py`: ghép cặp (số, nhãn) bằng regex, so sánh với giá trị của đúng key đó (chấp nhận dạng phần trăm, sai số làm tròn 0.0051); số không nhãn được phân loại "có trong dữ liệu" hoặc "không truy vết được".
- `negative_control.py`: cài 4 loại lỗi vào một báo cáo đúng và xác nhận verify phát hiện từng loại.

## Cấu hình và bảo mật

- Khoảng ngày khai báo một lần trong `dbt_project.yml` (`start_date`, `end_date`, `funnel_start_date`).
- Kết nối BigQuery dùng Application Default Credentials qua `gcloud`; `profiles.yml` nằm ngoài repo, có `maximum_bytes_billed` để chặn query quét quá nhiều dữ liệu.
- API key chỉ nằm trong `.env`, được `.gitignore` loại trừ; `.env.example` chỉ chứa tên biến.
