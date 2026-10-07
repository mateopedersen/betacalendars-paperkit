# February 2027

February 2027 has 28 days. Day 1 is Monday; its exact placement changes with the selected week start. PaperKit keeps that Gregorian structure independent of the current date, locale, and time zone.

## Grid topology

| Configuration | Natural rows | Leading adjacent positions | Trailing adjacent positions |
| --- | ---: | ---: | ---: |
| Sunday first | 5 | 1 | 6 |
| Monday first | 4 | 0 | 0 |

With a natural grid, the month uses the fewest complete seven-day rows that contain every date. Fixed-six-week mode always has 42 positions, which can make multi-month printed sets easier to align.

### Sunday-first date map

| Sun | Mon | Tue | Wed | Thu | Fri | Sat |
| --- | --- | --- | --- | --- | --- | --- |
| · | 1 | 2 | 3 | 4 | 5 | 6 |
| 7 | 8 | 9 | 10 | 11 | 12 | 13 |
| 14 | 15 | 16 | 17 | 18 | 19 | 20 |
| 21 | 22 | 23 | 24 | 25 | 26 | 27 |
| 28 | · | · | · | · | · | · |

Dots represent hidden adjacent-month positions in this generated reference table. Use `.placeholder` to show the neighboring day number or `.included` to expose its actual `CivilDate`.

## Printable A4 geometry

The default half-inch margins leave a printable area of approximately 523.28 × 769.89 points. With the default 44-point title, 24-point weekday header and 8-point outer spacing, the Sunday-first grid begins at y=112 points and measures 523.28 × 693.89 points. This month uses 5 rows, giving cells about 74.75 × 138.78 points before cell padding.

```swift
import BetaCalendarsPaperKit

let month = CivilMonth(year: 2027, month: 2)!
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

`HumanReadableReference.reference(forMonth: 2)` returns the canonical [February Calendar](https://www.betacalendars.com/february-calendar.html) URL as offline metadata. The library does not open this URL or make network requests.
