# Hướng dẫn cài đặt và chạy

**Yêu cầu:** Python 3.12, Git, [Google Cloud CLI](https://cloud.google.com/sdk/docs/install), một GCP project có BigQuery (sandbox miễn phí là đủ), một API key Gemini từ Google AI Studio.

## 1. Cài đặt

Lệnh PowerShell trên Windows:

```powershell
git clone https://github.com/haona0310/data_in_ga4.git
cd data_in_ga4
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1          # macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
gcloud auth application-default login
```

## 2. Cấu hình

Tạo file `.env` từ mẫu và điền giá trị của bạn:

```powershell
Copy-Item .env.example .env
```

| Biến | Ý nghĩa |
|---|---|
| `GCP_PROJECT_ID` | Project BigQuery nơi dbt tạo bảng |
| `GEMINI_API_KEY` | API key Gemini (không bao giờ commit) |
| `GEMINI_MODEL` | Tên model, ví dụ `models/gemini-3.5-flash` |
| `BQ_DATASET` | (Tùy chọn) dataset chứa các mart, mặc định `dbt_dev` |

Tạo file cấu hình dbt tại `~/.dbt/profiles.yml` (nằm ngoài repo):

```yaml
dbt_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: <your-gcp-project-id>
      dataset: dbt_dev
      location: US                     # bắt buộc: dataset nguồn nằm ở US
      threads: 4
      maximum_bytes_billed: 1500000000 # chặn query quét quá 1,5 GB
```

## 3. Chạy

```powershell
cd dbt_project
dbt build            # tạo stg_events và 3 mart, chạy toàn bộ test theo thứ tự phụ thuộc
cd ..
python src/extract.py           # đọc 3 mart → outputs/mart_snapshot.json
python src/generate_report.py   # gọi LLM → outputs/runs/run_<id>.json và .md
python src/verify.py            # kiểm chứng → outputs/verification/
python src/negative_control.py  # kiểm tra ngược công cụ kiểm chứng
```

Chạy mọi lệnh `python` từ thư mục gốc của repo; chạy lệnh `dbt` từ thư mục `dbt_project/`.
