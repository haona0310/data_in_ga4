import json

from verify import RESULTS_DIR, RUNS_DIR, SNAPSHOT_PATH, TAGGED_PATTERN, verify_run


def inject_wrong_value(report: str) -> str:
    """Cộng 7 vào con số có nhãn đầu tiên → giá trị sai."""
    m = TAGGED_PATTERN.search(report)
    wrong = f"{float(m.group(1)) + 7:.2f}"
    return report[:m.start(1)] + wrong + report[m.end(1):]


def inject_unknown_key(report: str) -> str:
    """Đổi nhãn đầu tiên thành một key không tồn tại."""
    m = TAGGED_PATTERN.search(report)
    return report[:m.start(2)] + "funnel.rate_fake_metric" + report[m.end(2):]


def inject_untraceable(report: str) -> str:
    """Thêm một câu chứa con số bịa, không có nhãn."""
    return report + "\n\nDoanh thu dự kiến tăng 12.34% trong quý tới."


def remove_tag(report: str) -> str:
    """Xóa nhãn của con số đầu tiên, giữ nguyên con số."""
    m = TAGGED_PATTERN.search(report)
    return report[:m.start(2) - 1] + report[m.end(2) + 1:]


CASES = [
    ("Sai giá trị", inject_wrong_value, "n_wrong_value"),
    ("Key không tồn tại", inject_unknown_key, "n_unknown_key"),
    ("Số bịa không nhãn", inject_untraceable, "n_untraceable"),
    ("Thiếu nhãn", remove_tag, "n_untagged_in_data"),
]


def main():
    metrics = json.loads(SNAPSHOT_PATH.read_text(encoding="utf-8"))["metrics"]

    # Lấy lần chạy v3 mới nhất làm báo cáo gốc
    runs = [json.loads(p.read_text(encoding="utf-8")) for p in sorted(RUNS_DIR.glob("run_*.json"))]
    run = [r for r in runs if r.get("report_tagged")][-1]
    baseline = verify_run(run, metrics)["summary"]
    print(f"Báo cáo gốc: {run['run_id']}\n")

    results = []
    for name, inject, field in CASES:
        mutated_run = {**run, "report_tagged": inject(run["report_tagged"])}
        mutated = verify_run(mutated_run, metrics)["summary"]
        detected = mutated[field] == baseline[field] + 1
        results.append({"case": name, "field": field, "baseline": baseline[field],
                         "after_injection": mutated[field], "detected": detected})
        print(f"{'PASS' if detected else 'FAIL'} | {name}: {field} {baseline[field]} → {mutated[field]}")

    out_path = RESULTS_DIR / "negative_control.json"
    out_path.write_text(json.dumps({"base_run": run["run_id"], "cases": results},
                                   indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nĐã lưu {out_path}")


if __name__ == "__main__":
    main()