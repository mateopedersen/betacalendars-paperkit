# Calendar Grids at the 2026–2027 Boundary

The year boundary is a useful check that calendar layout follows Gregorian civil rules rather than a fixed template. December 2026 starts on Tuesday and January 2027 starts on Friday. The first day of each month therefore occupies a different weekday column.

## Compare the neighboring months

```swift
import BetaCalendarsPaperKit

let december = CivilMonth(year: 2026, month: 12)!
let january = december.nextMonth!
let decemberGrid = MonthGrid(month: december, weekStart: .sunday, mode: .natural)
let januaryGrid = MonthGrid(month: january, weekStart: .sunday, mode: .natural)

assert(january == CivilMonth(year: 2027, month: 1)!)
assert(decemberGrid.rows.first![0].day == nil)
assert(januaryGrid.rows.first![0].day == nil)
```

With a Sunday-first layout, December 1 appears in Tuesday's column and January 1 appears in Friday's column. January needs six natural rows when the week starts Sunday, while Monday-first January fits five. A fixed-six-week grid reserves 42 positions for either month.

## Keep adjacent dates explicit

Use `.hidden` for empty cells, `.placeholder` to show neighboring day numbers without exposing them as selectable dates, or `.included` when adjacent dates need full civil-date values. All three policies preserve cell row, column, weekday, and month relation.

The `CivilMonth.nextMonth` transition is checked at the year boundary without constructing a timestamp, so the result cannot shift with daylight-saving changes or device time zone.
