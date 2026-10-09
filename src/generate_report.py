import json
import os
import re
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv
from google import genai
from google.genai import types
from pydantic import BaseModel

SNAPSHOT_PATH = Path("outputs/mart_snapshot.json")
RUNS_DIR = Path("outputs/runs")
PROMPT_VERSION = "v3"

# Mẫu nhãn key: dấu cách (nếu có) + [key] — dùng để xóa nhãn khi xuất báo cáo cho người đọc
TAG_PATTERN = re.compile(r"\s*\[[a-z0-9_.]+\]")

SYSTEM_INSTRUCTION = """Bạn là chuyên viên phân tích dữ liệu e-commerce. Viết báo cáo insight bằng tiếng Việt
từ số liệu được cung cấp, trả lời ba câu hỏi: phễu chuyển đổi, doanh thu và chuyển đổi
theo kênh, khác biệt hành vi theo thiết bị.

QUY TẮC VỀ SỐ LIỆU (bắt buộc):
- Chỉ dùng số liệu có trong phần "metrics". Không tự tính số mới: không cộng, trừ, lấy chênh lệch,
  hay tạo tỷ lệ mới từ các số đã cho.
- Ngay sau MỖI con số trong báo cáo (sau dấu % nếu có), gắn nhãn là key chính xác của số đó
  trong "metrics", đặt trong ngoặc vuông. Đơn vị bằng chữ viết SAU nhãn. Ví dụ:
    "tỷ lệ xem đến mua hàng đạt 6.53% [funnel.rate_view_to_purchase]"
    "giá trị đơn trung bình 66.32 [revenue.organic.aov] USD"
    "208942 [device.desktop.n_sessions] phiên"
- Định dạng số: số nguyên viết liền, không dấu phân cách hàng nghìn (55502);
  số thập phân dùng dấu chấm; tỷ lệ viết dạng phần trăm làm tròn 2 chữ số (6.53%);
  các số thập phân khác làm tròn 2 chữ số (66.32).
- Không viết ngày tháng, năm. Không đánh số tiêu đề hay danh sách bằng chữ số.
  Khi cần nói số lượng nhóm, viết bằng chữ (ba thiết bị, năm kênh).

BỐI CẢNH DỮ LIỆU (phải nêu trong báo cáo khi liên quan):
- Phễu (funnel) dùng giai đoạn ngắn hơn hai phần còn lại, vì trước đó sự kiện add_to_cart
  thiếu tracking. Không so sánh trực tiếp số của phễu với số của doanh thu hoặc thiết bị.
- Một phần phiên mua hàng không ghi nhận add_to_cart (funnel.n_sessions_purchase_without_cart),
  nên tỷ lệ xem → giỏ hàng có thể bị đánh giá thấp và giỏ hàng → thanh toán có thể bị đánh giá cao.
  Chỉ số đáng tin nhất của phễu là funnel.rate_view_to_purchase.
- Kênh "unknown" là nguồn truy cập bị làm mờ trong dữ liệu mẫu, không phải một kênh thật.
- Chênh lệch tỷ lệ chuyển đổi giữa các kênh và giữa các thiết bị rất nhỏ. Không diễn giải
  thành "khác biệt rõ rệt" hay "vượt trội"; dùng cách nói thận trọng.

ĐỊNH DẠNG: viết bằng Markdown, gồm bốn phần với tiêu đề cấp 2 (##), không đánh số:
"Lưu ý về dữ liệu", "Phễu chuyển đổi", "Doanh thu theo kênh", "Hành vi theo thiết bị".
Mỗi phần một hoặc hai đoạn ngắn. Tổng độ dài khoảng 300-400 từ."""


class LLMReport(BaseModel):
    report: str


def strip_tags(text: str) -> str:
    """Xóa các nhãn [key] để ra văn bản sạch cho người đọc."""
    return TAG_PATTERN.sub("", text)


def build_user_prompt(snapshot: dict) -> str:
    return "Số liệu (JSON):\n" + json.dumps(snapshot, indent=2, ensure_ascii=False)


def build_markdown(run: dict, snapshot: dict) -> str:
    """Báo cáo dạng đọc được: phần đầu do code viết, phần thân do LLM viết (đã xóa nhãn)."""
    periods = snapshot["periods"]
    header = [
        "# Báo cáo insight GA4 (sinh tự động)",
        "",
        f"- Model: `{run['model']}` | Prompt: `{run['prompt_version']}` | Lần chạy: `{run['run_id']}`",
        f"- Giai đoạn phễu: {periods['funnel']['start']} → {periods['funnel']['end']}",
        f"- Giai đoạn doanh thu và thiết bị: {periods['revenue']['start']} → {periods['revenue']['end']}",
        "",
        "---",
        "",
    ]
    body = strip_tags(run["report_tagged"]) if run["report_tagged"] else "(Không đọc được phản hồi của LLM)"
    return "\n".join(header) + body + "\n"


def main():
    load_dotenv()
    api_key = os.getenv("GEMINI_API_KEY")
    model = os.getenv("GEMINI_MODEL")
    if not api_key or not model:
        raise ValueError("Thiếu GEMINI_API_KEY hoặc GEMINI_MODEL trong file .env")

    snapshot = json.loads(SNAPSHOT_PATH.read_text(encoding="utf-8"))
    client = genai.Client(api_key=api_key)

    response = client.models.generate_content(
        model=model,
        contents=build_user_prompt(snapshot),
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_INSTRUCTION,
            response_mime_type="application/json",
            response_schema=LLMReport,
        ),
    )

    report_tagged = response.parsed.report if response.parsed else None
    if report_tagged:
        # Model đôi khi trả về chuỗi "\n" (2 ký tự) thay vì dấu xuống dòng thật
        report_tagged = report_tagged.replace("\\n", "\n")

    run_id = datetime.now().strftime("%Y%m%d_%H%M%S")
    run = {
        "run_id": run_id,
        "model": model,
        "prompt_version": PROMPT_VERSION,
        "raw_response": response.text,
        "report_tagged": report_tagged,
    }

    RUNS_DIR.mkdir(parents=True, exist_ok=True)
    json_path = RUNS_DIR / f"run_{run_id}.json"
    md_path = RUNS_DIR / f"run_{run_id}.md"
    json_path.write_text(json.dumps(run, indent=2, ensure_ascii=False), encoding="utf-8")
    md_path.write_text(build_markdown(run, snapshot), encoding="utf-8")
    print(f"Đã lưu {json_path} và {md_path}")


if __name__ == "__main__":
    main()