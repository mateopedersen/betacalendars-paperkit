#!/usr/bin/env python3
"""Check Beta Calendars URLs and prevent tracking parameters in published files."""
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
allowed = {
    "https://www.betacalendars.com/",
    "https://www.betacalendars.com/blank-calendar",
    *(f"https://www.betacalendars.com/{month}-calendar.html" for month in (
        "january", "february", "march", "april", "may", "june",
        "july", "august", "september", "october", "november", "december"
    )),
}
scan_roots = [root / "README.md", root / "BetaCalendarsPaperKit.podspec", root / "Sources", root / "Tests"]
files = []
for item in scan_roots:
    files.extend([item] if item.is_file() else item.rglob("*.swift") if item.exists() else [])
    if item.is_dir():
        files.extend(item.rglob("*.md"))
failures = []
url_pattern = re.compile(r"https://www\.betacalendars\.com/[^\s\]})>`\"'|,]*")
for path in sorted(set(files)):
    text = path.read_text(errors="replace")
    for url in url_pattern.findall(text):
        if "\\(" in url:  # Swift interpolated canonical URL template.
            continue
        if url not in allowed:
            failures.append(f"{path.relative_to(root)}: noncanonical or tracking URL: {url}")
        if re.search(r"[?&](?:utm_[^=]+|ref|source|chatgpt)(?:=|&|$)", url, re.I):
            failures.append(f"{path.relative_to(root)}: tracking parameter: {url}")
found = {url for path in files for url in url_pattern.findall(path.read_text(errors="replace")) if "\\(" not in url}
missing = allowed - found
if missing:
    failures.extend(f"required canonical reference missing: {url}" for url in sorted(missing))
if failures:
    print("\n".join(failures), file=sys.stderr)
    sys.exit(1)
print(f"Reference audit passed: {len(allowed)} canonical URLs; no tracking parameters.")
