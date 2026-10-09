import json
import re
from collections import Counter
from pathlib import Path

SNAPSHOT_PATH = Path("outputs/mart_snapshot.json")
RUNS_DIR = Path("outputs/runs")
RESULTS_DIR = Path("outputs/verification")

NUMBER = r"\d+(?:\.\d+)?"
TAGGED_PATTERN = re.compile(rf"({NUMBER})%?\s*\[([a-z0-9_.]+)\]")  # số + nhãn [key]
NUMBER_PATTERN = re.compile(NUMBER)                                 # số bất kỳ
ABS_TOL = 0.0051  # sai số do làm tròn 2 chữ số thập phân


def is_percent_metric(key: str) -> bool:
    """Chỉ số dạng tỷ lệ/tỷ trọng: trong văn bản có thể được viết dạng phần trăm."""
    last_part = key.split(".")[-1]
    return "rate" in last_part or "share" in last_part


def readable_forms(key: str, value: float) -> list:
    """Các dạng giá trị có thể xuất hiện trong văn bản: gốc, và dạng % nếu là tỷ lệ."""
    forms = [value]
    if is_percent_metric(key):
        forms.append(value * 100)
    return forms


def number_matches(number: float, key: str, value: float) -> bool:
    return any(abs(number - form) <= ABS_TOL for form in readable_forms(key, value))


def check_tagged(number: float, key: str, metrics: dict) -> str:
    """Số có nhãn: kiểm tra đúng với CHÍNH chỉ số được gắn nhãn."""
    if key not in metrics:
        return "unknown_key"
    return "correct" if number_matches(number, key, metrics[key]) else "wrong_value"


def check_untagged(number: float, metrics: dict) -> str:
    """Số không có nhãn: chỉ kiểm tra được nó có xuất hiện ở đâu đó trong dữ liệu hay không."""
    if any(number_matches(number, key, value) for key, value in metrics.items()):
        return "untagged_in_data"
    return "untraceable"


def verify_run(run: dict, metrics: dict) -> dict:
    report = run["report_tagged"]
    if not report:
        return {"run_id": run["run_id"], "error": "LLM response could not be parsed"}

    tagged = []
    for number_text, key in TAGGED_PATTERN.findall(report):
        number = float(number_text)
        tagged.append({
            "number": number,
            "key": key,
            "truth": metrics.get(key),
            "status": check_tagged(number, key, metrics),
        })

    # Xóa các cặp (số + nhãn) đã xử lý; số nào còn lại là số không có nhãn
    remaining_text = TAGGED_PATTERN.sub(" ", report)
    untagged = [
        {"number": float(n), "status": check_untagged(float(n), metrics)}
        for n in NUMBER_PATTERN.findall(remaining_text)
    ]

    counts = Counter(item["status"] for item in tagged + untagged)
    n_tagged = len(tagged)
    n_numbers = n_tagged + len(untagged)

    summary = {
        "n_numbers": n_numbers,
        "n_tagged": n_tagged,
        "n_correct": counts["correct"],
        "n_wrong_value": counts["wrong_value"],
        "n_unknown_key": counts["unknown_key"],
        "n_untagged_in_data": counts["untagged_in_data"],
        "n_untraceable": counts["untraceable"],
        "tagged_accuracy": counts["correct"] / n_tagged if n_tagged else None,
        "verified_share": counts["correct"] / n_numbers if n_numbers else None,
    }
    return {
        "run_id": run["run_id"],
        "model": run["model"],
        "prompt_version": run["prompt_version"],
        "summary": summary,
        "tagged_numbers": tagged,
        "untagged_numbers": untagged,
    }


def main():
    metrics = json.loads(SNAPSHOT_PATH.read_text(encoding="utf-8"))["metrics"]
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    all_summaries = []
    for run_path in sorted(RUNS_DIR.glob("run_*.json")):
        run = json.loads(run_path.read_text(encoding="utf-8"))
        if "report_tagged" not in run:
            print(f"{run['run_id']}: bỏ qua (định dạng prompt cũ {run['prompt_version']})")
            continue

        result = verify_run(run, metrics)
        out_path = RESULTS_DIR / f"verification_{run['run_id']}.json"
        out_path.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")

        if "error" in result:
            print(f"{run['run_id']}: LỖI - {result['error']}")
            continue

        s = result["summary"]
        all_summaries.append({"run_id": run["run_id"], "model": run["model"],
                              "prompt_version": run["prompt_version"], **s})
        print(
            f"{run['run_id']}: {s['n_numbers']} số, có nhãn {s['n_tagged']} "
            f"(đúng {s['n_correct']}, sai giá trị {s['n_wrong_value']}, key không tồn tại {s['n_unknown_key']}), "
            f"không nhãn {s['n_untagged_in_data'] + s['n_untraceable']} "
            f"(trong đó không truy vết được {s['n_untraceable']})"
        )

    summary_path = RESULTS_DIR / "summary.json"
    summary_path.write_text(json.dumps(all_summaries, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nĐã lưu kết quả vào {RESULTS_DIR}")


if __name__ == "__main__":
    main()