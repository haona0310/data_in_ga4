import json
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery

OUTPUT_DIR = Path("outputs")
SNAPSHOT_PATH = OUTPUT_DIR / "mart_snapshot.json"

# Các cột gửi cho LLM của từng mart (bỏ cột kiểm tra chất lượng như n_sessions_multi_device)
REVENUE_COLUMNS = [
    "n_users", "n_buyers", "user_conversion_rate",
    "n_transactions", "revenue", "revenue_share", "aov",
]
DEVICE_COLUMNS = [
    "n_sessions", "session_share", "avg_pageviews_per_session",
    "avg_engagement_seconds", "session_conversion_rate",
]


def read_table(client: bigquery.Client, project_id: str, dataset: str, table: str) -> pd.DataFrame:
    """Đọc toàn bộ một bảng mart thành DataFrame."""
    sql = f"SELECT * FROM `{project_id}.{dataset}.{table}`"
    return client.query(sql).to_dataframe(create_bqstorage_client=False)


def to_number(column: str, value):
    """Cột bắt đầu bằng n_ là số đếm → int; còn lại → float."""
    return int(value) if column.startswith("n_") else float(value)


def build_metrics(funnel: pd.DataFrame, revenue: pd.DataFrame, device: pd.DataFrame) -> dict:
    """Chuyển 3 mart thành dict phẳng: key cố định → giá trị."""
    metrics = {}

    # mart_funnel chỉ có 1 dòng
    funnel_row = funnel.iloc[0]
    for col in funnel.columns:
        if col.startswith(("n_", "rate_")):
            metrics[f"funnel.{col}"] = to_number(col, funnel_row[col])

    # mart_revenue_by_source: mỗi kênh một dòng
    for _, row in revenue.iterrows():
        for col in REVENUE_COLUMNS:
            metrics[f"revenue.{row['channel']}.{col}"] = to_number(col, row[col])

    # mart_device_behavior: mỗi thiết bị một dòng
    for _, row in device.iterrows():
        for col in DEVICE_COLUMNS:
            metrics[f"device.{row['device_category']}.{col}"] = to_number(col, row[col])

    return metrics


def build_periods(funnel: pd.DataFrame, revenue: pd.DataFrame, device: pd.DataFrame) -> dict:
    """Khoảng thời gian của từng mart, để LLM không ghép số của các giai đoạn khác nhau."""
    return {
        name: {
            "start": str(df["period_start"].iloc[0]),
            "end": str(df["period_end"].iloc[0]),
        }
        for name, df in [("funnel", funnel), ("revenue", revenue), ("device", device)]
    }


def main():
    load_dotenv()
    project_id = os.getenv("GCP_PROJECT_ID")
    dataset = os.getenv("BQ_DATASET", "dbt_dev")
    if not project_id:
        raise ValueError("Thiếu GCP_PROJECT_ID trong file .env")

    client = bigquery.Client(project=project_id)
    funnel = read_table(client, project_id, dataset, "mart_funnel")
    revenue = read_table(client, project_id, dataset, "mart_revenue_by_source")
    device = read_table(client, project_id, dataset, "mart_device_behavior")

    snapshot = {
        "periods": build_periods(funnel, revenue, device),
        "metrics": build_metrics(funnel, revenue, device),
    }

    OUTPUT_DIR.mkdir(exist_ok=True)
    SNAPSHOT_PATH.write_text(json.dumps(snapshot, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Đã lưu {len(snapshot['metrics'])} số liệu vào {SNAPSHOT_PATH}")


if __name__ == "__main__":
    main()