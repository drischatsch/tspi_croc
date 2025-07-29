import re
from pathlib import Path


ROW_RE = re.compile(
    r"""^(?P<group>\S[\S ]*?)\s+
        (?P<internal>[0-9.]+e[+-]\d+)\s+
        (?P<switching>[0-9.]+e[+-]\d+)\s+
        (?P<leakage>[0-9.]+e[+-]\d+)\s+
        (?P<total>[0-9.]+e[+-]\d+)\s+
        (?P<pct>[0-9.]+)%\s*$""",
    re.X | re.M
)


def extract_powers(power_report_path: str) -> list:
    power_report = Path(power_report_path)
    if not power_report.is_file():
        raise FileNotFoundError(f"Power report file not found: {power_report_path}")
    
    text = power_report.read_text()
    rows = []
    for m in ROW_RE.finditer(text):
        d = m.groupdict()
        if d["group"].lower().startswith("total") and d["pct"] == "100.0":
            # keep total but mark
            d["is_total"] = True
        else:
            d["is_total"] = False
        for k in ("internal","switching","leakage","total","pct"):
            d[k] = float(d[k])
        rows.append(d)
    if not rows:
        raise ValueError("No rows matched; check format or regex.")
    return rows