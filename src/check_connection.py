import os 

from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv()
project_id = os.getenv('GCP_PROJECT_ID')
if not project_id:
    raise ValueError('Thiếu GCP_PROJECT_ID trong file .env')

# Tạo client 
client = bigquery.Client(project = project_id)

sql = """
SELECT event_name, COUNT(*) AS n_events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX = '20201101'
GROUP BY event_name
ORDER BY n_events DESC
"""

# Dry run: hỏi BigQuery query này sẽ quét bao nhiêu byte, chưa chạy thật
dry_run_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
dry_run_job = client.query(sql, job_config=dry_run_config)
print(f"Dự kiến quét: {dry_run_job.total_bytes_processed / 1024**2:.2f} MB")

# Chạy thật và chuyển kết quả sang pandas DataFrame
df = client.query(sql).to_dataframe()
print(df)
