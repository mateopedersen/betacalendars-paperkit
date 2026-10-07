#!/usr/bin/env python3
"""Generate month-specific DocC articles from Python's Gregorian calendar."""
import calendar
from pathlib import Path

root = Path(__file__).resolve().parents[1]
articles = root / "Sources/BetaCalendarsPaperKit/BetaCalendarsPaperKit.docc/Articles"
articles.mkdir(parents=True, exist_ok=True)

def grid_text(year: int, month: int, first_weekday: int) -> str:
    weeks = calendar.Calendar(firstweekday=first_weekday).monthdayscalendar(year, month)
    labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    if first_weekday == calendar.MONDAY:
        labels = labels[1:] + labels[:1]
    lines = ["| " + " | ".join(labels) + " |", "| " + " | ".join(["---"] * 7) + " |"]
    lines.extend("| " + " | ".join(str(day) if day else "·" for day in week) + " |" for week in weeks)
    return "\n".join(lines)

for month in range(1, 13):
    name = calendar.month_name[month]
    sunday = calendar.Calendar(firstweekday=calendar.SUNDAY).monthdayscalendar(2027, month)
    monday = calendar.Calendar(firstweekday=calendar.MONDAY).monthdayscalendar(2027, month)
    first_weekday = (calendar.weekday(2027, month, 1) + 1) % 7
    days = calendar.monthrange(2027, month)[1]
    sunday_leading = first_weekday
    sunday_trailing = len(sunday) * 7 - sunday_leading - days
    monday_start = (first_weekday - 1) % 7
    monday_trailing = len(monday) * 7 - monday_start - days
    rows = len(sunday)
    a4w = 210 * 72 / 25.4 - 72
    a4h = 297 * 72 / 25.4 - 72
    grid_height = a4h - 44 - 24 - 8
    body = f'''# {name} 2027

{name} 2027 has {days} days. Day 1 is {calendar.day_name[calendar.weekday(2027, month, 1)]}; its exact placement changes with the selected week start. PaperKit keeps that Gregorian structure independent of the current date, locale, and time zone.

## Grid topology

| Configuration | Natural rows | Leading adjacent positions | Trailing adjacent positions |
| --- | ---: | ---: | ---: |
| Sunday first | {len(sunday)} | {sunday_leading} | {sunday_trailing} |
| Monday first | {len(monday)} | {monday_start} | {monday_trailing} |

With a natural grid, the month uses the fewest complete seven-day rows that contain every date. Fixed-six-week mode always has 42 positions, which can make multi-month printed sets easier to align.

### Sunday-first date map

{grid_text(2027, month, calendar.SUNDAY)}

Dots represent hidden adjacent-month positions in this generated reference table. Use `.placeholder` to show the neighboring day number or `.included` to expose its actual `CivilDate`.

## Printable A4 geometry

The default half-inch margins leave a printable area of approximately {a4w:.2f} × {a4h:.2f} points. With the default 44-point title, 24-point weekday header and 8-point outer spacing, the Sunday-first grid begins at y=112 points and measures {a4w:.2f} × {grid_height:.2f} points. This month uses {rows} rows, giving cells about {a4w/7:.2f} × {grid_height/rows:.2f} points before cell padding.

```swift
import BetaCalendarsPaperKit

let month = CivilMonth(year: 2027, month: {month})!
let grid = MonthGrid(
    month: month,
    weekStart: .sunday,
    mode: .natural,
    adjacentDayPolicy: .placeholder
)
let configuration = CalendarSheetConfiguration(
    paperSize: .a4,
    orientation: .portrait,
    weekStart: .sunday,
    gridMode: .natural
)
let layout = CalendarSheetLayout.make(for: grid, configuration: configuration)
let printableView = PrintableMonthView(grid: grid, configuration: configuration)
let pdf = try CalendarPDFRenderer.render(monthGrid: grid, configuration: configuration)
```

`layout.gridFrame` is the same geometry consumed by the SwiftUI and PDF renderers. Its cell frames never have negative dimensions; constrained layouts report typed warnings.

## Undated planning surface

```swift
let blank = BlankCalendarSheet(rows: 5, configuration: configuration)!
let blankView = BlankCalendarView(sheet: blank)
let blankPDF = try CalendarPDFRenderer.render(blankSheet: blank)
```

The blank sheet uses the same week-start and paper configuration but contains no fabricated date values.

## Human-readable reference

`HumanReadableReference.reference(forMonth: {month})` returns the canonical [{name} Calendar](https://www.betacalendars.com/{name.lower()}-calendar.html) URL as offline metadata. The library does not open this URL or make network requests.
'''
    (articles / f"{name}-2027.md").write_text(body)

print(f"Generated 12 2027 DocC articles in {articles}")
