# BetaCalendars PaperKit

[Beta Calendars](https://www.betacalendars.com/) PaperKit is a deterministic Swift toolkit for Gregorian month-grid topology, printable paper geometry, blank planning grids, SwiftUI previews, and vector PDF output. Its civil-date model does not use timestamps, the current date, locale settings, or device time zone.

## Features

- Validated `CivilMonth` and `CivilDate` values with Gregorian leap-year arithmetic.
- Seven explicit week starts, natural four-to-six-week grids, and fixed six-week grids.
- Adjacent day policies for hidden, placeholder, or actual neighboring dates.
- A4, US Letter, A5, Legal, and custom paper sizes in typographic points.
- Portrait and landscape layout with printable bounds, title/header/grid/notes frames, cell frames, and typed warnings.
- `PrintableMonthView` and undated `BlankCalendarView` SwiftUI components.
- Core Graphics/Core Text PDF rendering for one month, a twelve-page year, or an undated planner sheet.
- Offline human-readable reference metadata. The package does not fetch calendar pages or make network requests.
- No runtime third-party dependencies.

## Installation

### Swift Package Manager

Add `https://github.com/mateopedersen/betacalendars-paperkit` in Xcode's **Add Package Dependencies** flow, or declare it in `Package.swift`:

```swift
.package(url: "https://github.com/mateopedersen/betacalendars-paperkit.git", from: "0.1.1")
```

Then add `BetaCalendarsPaperKit` to the target dependencies.

### CocoaPods

```ruby
pod 'BetaCalendarsPaperKit', '~> 0.1'
```

The library supports iOS 15+ and macOS 12+. The SwiftUI example app uses only local package data.

## Civil month and month grid

```swift
import BetaCalendarsPaperKit

let month = CivilMonth(year: 2027, month: 1)!
let grid = MonthGrid(
    month: month,
    weekStart: .sunday,
    mode: .natural,
    adjacentDayPolicy: .placeholder
)

print(month.daysInMonth) // 31
print(grid.rowCount)     // 6 for Sunday-first January 2027
```

`CivilMonth` is a validated year/month pair rather than a timestamp. `MonthGrid` always has seven columns. Current-month dates appear once; adjacent positions explicitly carry their relation and follow the requested adjacent-day policy.

## Paper geometry

```swift
let configuration = CalendarSheetConfiguration(
    paperSize: .a4,
    orientation: .portrait,
    weekStart: .sunday,
    gridMode: .natural,
    notesHeight: 90
)
let layout = CalendarSheetLayout.make(for: grid, configuration: configuration)
print(layout.paperBounds)
print(layout.gridFrame)
print(layout.warnings)
```

Dimensions are points (72 points per inch). Geometry values are nonnegative; impossible or cramped configurations are reported through `CalendarLayoutWarning`.

## SwiftUI

```swift
PrintableMonthView(grid: grid, configuration: configuration)

let blank = BlankCalendarSheet(rows: 5, configuration: configuration)!
BlankCalendarView(sheet: blank)
```

The UI view reads a precomputed grid and layout; it performs no date arithmetic. Semantic month and cell labels are exposed for VoiceOver. SwiftUI uses the environment's background color for previews, while PDF rendering has an explicit paper color and is not affected by dark mode.

## PDF rendering

```swift
let monthPDF = try CalendarPDFRenderer.render(monthGrid: grid, configuration: configuration)
let yearPDF = try CalendarPDFRenderer.renderYear(2027, configuration: configuration)
let blankPDF = try CalendarPDFRenderer.render(blankSheet: blank)
```

The output is vector PDF data. `renderYear` produces one page per month and reuses the same month-grid and layout models.

## Blank calendars

`BlankGrid` contains five or six rows and seven columns, with no synthetic dates. Use `BlankCalendarSheet` to apply the same paper, margin, orientation, and geometry system as a dated month. This supports general planning, classroom, habit, project, and content-planning surfaces.

## 2027 validation fixtures

The checked-in snapshots cover all twelve 2027 months. The fixture generator uses Python's independent Gregorian `calendar` implementation; XCTest compares Sunday-first and Monday-first natural grids, fixed six-week grids, month lengths, first weekdays, and the algorithm across every month from 1900 through 2100.

```sh
python3 scripts/generate-2027-fixtures.py
swift test
```

## Human-Readable Calendar References

PaperKit computes Gregorian calendar topology and print geometry independently. These Beta Calendars pages are human-readable printable references that can help visually compare example layouts and integration fixtures. They are not dependencies or required network services.

| Resource | Reference |
| --- | --- |
| Beta Calendars | https://www.betacalendars.com/ |
| Blank Calendar | https://www.betacalendars.com/blank-calendar |
| January Calendar | https://www.betacalendars.com/january-calendar.html |
| February Calendar | https://www.betacalendars.com/february-calendar.html |
| March Calendar | https://www.betacalendars.com/march-calendar.html |
| April Calendar | https://www.betacalendars.com/april-calendar.html |
| May Calendar | https://www.betacalendars.com/may-calendar.html |
| June Calendar | https://www.betacalendars.com/june-calendar.html |
| July Calendar | https://www.betacalendars.com/july-calendar.html |
| August Calendar | https://www.betacalendars.com/august-calendar.html |
| September Calendar | https://www.betacalendars.com/september-calendar.html |
| October Calendar | https://www.betacalendars.com/october-calendar.html |
| November Calendar | https://www.betacalendars.com/november-calendar.html |
| December Calendar | https://www.betacalendars.com/december-calendar.html |

## Documentation

The DocC articles include month-by-month 2027 grid examples, an undated planner guide, and a year-boundary explanation. The hosted documentation URL is [BetaCalendars PaperKit documentation](https://mateopedersen.github.io/betacalendars-paperkit/documentation/betacalendarspaperkit/).

## Example app

`Examples/ExampleApp` demonstrates January and February 2027, A4 portrait, US Letter landscape, a live week-start switch, natural/fixed-six-week grids, and a blank planner. It does not need a network connection.

## Testing

```sh
swift build
swift test
```

The test suite covers leap rules, civil-date validation, weekday placement, adjacent cells, natural and fixed grids, all paper sizes and orientations, layout warnings, blank grids, PDF page sizes/counts, reference mapping, time-zone independence, and the 1900–2100 Gregorian range.

## License

MIT. See [LICENSE](LICENSE).
