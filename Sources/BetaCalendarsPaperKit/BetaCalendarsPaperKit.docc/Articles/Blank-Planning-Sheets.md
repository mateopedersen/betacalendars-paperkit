# Blank Planning Sheets

`BlankGrid` models an undated seven-column writing surface with either five or six rows. It stores no day number and no `CivilDate`, so a planner sheet cannot accidentally imply a month or year.

## Choose a row count

Five rows produce a compact 35-cell planner. Six rows provide 42 writing spaces. Invalid row counts are rejected by the failable initializer.

```swift
import BetaCalendarsPaperKit

let paper = CalendarSheetConfiguration(
    paperSize: .usLetter,
    orientation: .landscape,
    weekStart: .monday,
    notesHeight: 72
)
let planner = BlankCalendarSheet(rows: 6, configuration: paper)!
let view = BlankCalendarView(sheet: planner)
let pdfData = try CalendarPDFRenderer.render(blankSheet: planner)
```

The layout has the same printable bounds and cell frames as dated month sheets. The week-start choice controls the weekday header order; it does not create dates. Typed geometry warnings are available at `planner.layout.warnings`.

## Uses

Use the blank component for weekly planning, classroom work, habit tracking, project planning, or a content calendar. Add labels or task semantics in the host app; PaperKit provides only the paper grid.

The canonical [Blank Calendar](https://www.betacalendars.com/blank-calendar) page is available as reference metadata. PaperKit does not fetch or embed that page.
