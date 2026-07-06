import csv
import statistics
import sys
from pathlib import Path


# results/*.csv 파일을 읽어 한 줄 요약표를 만든다.
#
# benchmark client는 요청별 raw data를 남긴다.
# 이 파일은 그 raw data를 사람이 비교하기 쉬운 형태로 요약한다.


def percentile(values: list[float], pct: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = round((len(ordered) - 1) * pct)
    return ordered[index]


def summarize_file(path: Path) -> dict[str, str]:
    with path.open(newline="", encoding="utf-8") as csv_file:
        rows = list(csv.DictReader(csv_file))

    success_rows = [row for row in rows if row.get("success") == "True"]
    failed_rows = [row for row in rows if row.get("success") != "True"]
    latencies = [float(row["latency_ms"]) for row in success_rows]
    ttfts = [
        float(row["ttft_ms"])
        for row in success_rows
        if row.get("ttft_ms") not in ("", "None", None)
    ]

    first = rows[0] if rows else {}
    return {
        "file": str(path),
        "requests": str(len(rows)),
        "failed": str(len(failed_rows)),
        "concurrency": first.get("concurrency", ""),
        "prompt_size": first.get("prompt_size", ""),
        "max_tokens": first.get("max_tokens", ""),
        "stream": first.get("stream", ""),
        "latency_avg_ms": f"{statistics.mean(latencies):.1f}" if latencies else "0.0",
        "latency_p50_ms": f"{percentile(latencies, 0.50):.1f}" if latencies else "0.0",
        "latency_p95_ms": f"{percentile(latencies, 0.95):.1f}" if latencies else "0.0",
        "ttft_p50_ms": f"{percentile(ttfts, 0.50):.1f}" if ttfts else "",
        "ttft_p95_ms": f"{percentile(ttfts, 0.95):.1f}" if ttfts else "",
    }


def main() -> None:
    result_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "results")
    csv_files = sorted(result_dir.glob("*.csv"))
    if not csv_files:
        print(f"no csv files found in {result_dir}")
        return

    summaries = [summarize_file(path) for path in csv_files]
    columns = list(summaries[0].keys())

    print(",".join(columns))
    for row in summaries:
        print(",".join(row[column] for column in columns))


if __name__ == "__main__":
    main()
