#!/usr/bin/env python3
"""Generate independent 2027 calendar-grid snapshots with Python's Gregorian calendar."""
import calendar
import json
from pathlib import Path


def grid(year: int, month: int, first_weekday: int, fixed_six: bool = False) -> list[list[int]]:
    cal = calendar.Calendar(firstweekday=first_weekday)
    weeks = cal.monthdayscalendar(year, month)
    weeks = [[day for day in week] for week in weeks]
    if fixed_six:
        weeks += [[0] * 7 for _ in range(6 - len(weeks))]
    return weeks


months = []
for month in range(1, 13):
    months.append({
        "month": month,
        "firstWeekdaySundayZero": (calendar.weekday(2027, month, 1) + 1) % 7,
        "dayCount": calendar.monthrange(2027, month)[1],
        "naturalSunday": grid(2027, month, calendar.SUNDAY),
        "naturalMonday": grid(2027, month, calendar.MONDAY),
        "fixedSunday": grid(2027, month, calendar.SUNDAY, fixed_six=True),
    })

destination = Path(__file__).resolve().parents[1] / "Tests/BetaCalendarsPaperKitTests/Fixtures/2027-grid-fixtures.json"
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(json.dumps({"year": 2027, "months": months}, indent=2) + "\n")
print(f"Generated {len(months)} month snapshots at {destination}")
