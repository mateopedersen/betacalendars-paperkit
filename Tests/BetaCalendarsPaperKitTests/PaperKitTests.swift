import Foundation
import XCTest
@testable import BetaCalendarsPaperKit
#if canImport(PDFKit)
import PDFKit
#endif

final class PaperKitTests: XCTestCase {
    private struct FixtureFile: Decodable { let year: Int; let months: [MonthFixture] }
    private struct MonthFixture: Decodable {
        let month: Int
        let firstWeekdaySundayZero: Int
        let dayCount: Int
        let naturalSunday: [[Int]]
        let naturalMonday: [[Int]]
        let fixedSunday: [[Int]]
    }

    private func fixture() throws -> FixtureFile {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "2027-grid-fixtures", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(FixtureFile.self, from: Data(contentsOf: url))
    }

    func testGregorianLeapYearRules() {
        XCTAssertFalse(CivilMonth.isLeapYear(1900))
        XCTAssertTrue(CivilMonth.isLeapYear(2000))
        XCTAssertTrue(CivilMonth.isLeapYear(2024))
        XCTAssertFalse(CivilMonth.isLeapYear(2027))
        XCTAssertFalse(CivilMonth.isLeapYear(2100))
        XCTAssertTrue(CivilMonth.isLeapYear(2400))
    }

    func testCivilMonthValidationAndBoundaries() throws {
        XCTAssertNil(CivilMonth(year: 2027, month: 0))
        XCTAssertNil(CivilMonth(year: 2027, month: 13))
        XCTAssertNil(CivilMonth(year: 0, month: 1))
        let january = try XCTUnwrap(CivilMonth(year: 2027, month: 1))
        let february = try XCTUnwrap(CivilMonth(year: 2027, month: 2))
        XCTAssertLessThan(january, february)
        XCTAssertLessThan(try XCTUnwrap(CivilMonth(year: 2026, month: 12)), january)
        XCTAssertEqual(january.previousMonth, CivilMonth(year: 2026, month: 12))
        XCTAssertEqual(try XCTUnwrap(CivilMonth(year: 2027, month: 12)).nextMonth, CivilMonth(year: 2028, month: 1))
        XCTAssertNil(CivilMonth(year: 1, month: 1)?.previousMonth)
        XCTAssertNil(CivilMonth(year: 9999, month: 12)?.nextMonth)
        XCTAssertNil(CivilDate(year: 2027, month: 2, day: 29))
        XCTAssertEqual(CivilDate(year: 2024, month: 2, day: 29)?.description, "2024-02-29")
    }

    func testDaysInMonth() throws {
        let expected = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        for month in 1...12 {
            XCTAssertEqual(try XCTUnwrap(CivilMonth(year: 2027, month: month)).daysInMonth, expected[month - 1])
        }
        XCTAssertEqual(CivilMonth(year: 2024, month: 2)?.daysInMonth, 29)
    }

    func testAllMonthsFrom1900Through2100AgainstGregorianCalendar() throws {
        var referenceCalendar = Calendar(identifier: .gregorian)
        referenceCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for year in 1900...2100 {
            for monthNumber in 1...12 {
                let month = try XCTUnwrap(CivilMonth(year: year, month: monthNumber))
                let grid = MonthGrid(month: month, weekStart: .sunday, mode: .natural, adjacentDayPolicy: .hidden)
                let actualDays = grid.cells.filter { $0.relation == .currentMonth }
                XCTAssertEqual(actualDays.count, month.daysInMonth, "\(month)")
                XCTAssertEqual(Set(actualDays.compactMap(\.day)).count, month.daysInMonth, "\(month)")
                XCTAssertTrue((4...6).contains(grid.rowCount), "\(month)")
                XCTAssertEqual(grid.rows.count * 7, grid.cells.count)
                for cell in actualDays {
                    let date = try XCTUnwrap(cell.date)
                    XCTAssertEqual(date.day, cell.day)
                    let components = DateComponents(year: year, month: monthNumber, day: date.day)
                    let referenceDate = try XCTUnwrap(referenceCalendar.date(from: components))
                    let expectedWeekday = referenceCalendar.component(.weekday, from: referenceDate) - 1
                    XCTAssertEqual(cell.weekday.rawValue, expectedWeekday, "\(date)")
                }
                let fixed = MonthGrid(month: month, mode: .fixedSixWeeks)
                XCTAssertEqual(fixed.cells.count, 42, "\(month)")
                XCTAssertEqual(fixed.rowCount, 6)
            }
        }
    }

    func testWeekStartsAndGridModes() throws {
        let month = try XCTUnwrap(CivilMonth(year: 2027, month: 1))
        for weekStart in WeekStart.allCases {
            let grid = MonthGrid(month: month, weekStart: weekStart)
            XCTAssertEqual(grid.rows.first?.first?.weekday, weekStart.weekday)
            for row in grid.rows {
                XCTAssertEqual(row.count, 7)
                XCTAssertEqual(row.map(\.column), Array(0..<7))
            }
        }
        let february = MonthGrid(month: try XCTUnwrap(CivilMonth(year: 2027, month: 2)), weekStart: .sunday)
        XCTAssertEqual(february.rowCount, 5)
        XCTAssertEqual(february.rows[0][0].day, nil)
        XCTAssertEqual(february.rows[0][0].relation, .previousMonth)
        XCTAssertEqual(february.rows[0][0].weekday, .sunday)
    }

    func testAdjacentDayPolicies() throws {
        let month = try XCTUnwrap(CivilMonth(year: 2027, month: 2))
        let hidden = MonthGrid(month: month, weekStart: .sunday, adjacentDayPolicy: .hidden)
        let placeholder = MonthGrid(month: month, weekStart: .sunday, adjacentDayPolicy: .placeholder)
        let included = MonthGrid(month: month, weekStart: .sunday, adjacentDayPolicy: .included)
        let leadingHidden = try XCTUnwrap(hidden.cells.first)
        let leadingPlaceholder = try XCTUnwrap(placeholder.cells.first)
        let leadingIncluded = try XCTUnwrap(included.cells.first)
        XCTAssertEqual(leadingHidden.relation, .previousMonth)
        XCTAssertNil(leadingHidden.day)
        XCTAssertNil(leadingHidden.date)
        XCTAssertEqual(leadingPlaceholder.day, 31)
        XCTAssertNil(leadingPlaceholder.date)
        XCTAssertEqual(leadingIncluded.day, 31)
        XCTAssertEqual(leadingIncluded.date, CivilDate(year: 2027, month: 1, day: 31))
        XCTAssertNil(hidden.cells.last?.date)
        XCTAssertNil(placeholder.cells.last?.date)
        XCTAssertEqual(included.cells.last?.date, CivilDate(year: 2027, month: 3, day: 6))
        let trailing = try XCTUnwrap(included.cells.last)
        XCTAssertEqual(trailing.relation, .nextMonth)
        XCTAssertEqual(trailing.date, CivilDate(year: 2027, month: 3, day: 6))
    }

    func testGenerated2027Fixtures() throws {
        let file = try fixture()
        XCTAssertEqual(file.year, 2027)
        XCTAssertEqual(file.months.count, 12)
        for item in file.months {
            let month = try XCTUnwrap(CivilMonth(year: file.year, month: item.month))
            XCTAssertEqual(month.daysInMonth, item.dayCount)
            let sunday = MonthGrid(month: month, weekStart: .sunday)
            let monday = MonthGrid(month: month, weekStart: .monday)
            let fixed = MonthGrid(month: month, weekStart: .sunday, mode: .fixedSixWeeks)
            XCTAssertEqual(sunday.cells.first(where: { $0.day == 1 })?.weekday.rawValue, item.firstWeekdaySundayZero)
            XCTAssertEqual(sunday.rows.map { $0.map { $0.day ?? 0 } }, item.naturalSunday, "month \(item.month)")
            XCTAssertEqual(monday.rows.map { $0.map { $0.day ?? 0 } }, item.naturalMonday, "month \(item.month)")
            XCTAssertEqual(fixed.rows.map { $0.map { $0.day ?? 0 } }, item.fixedSunday, "month \(item.month)")
        }
    }

    func testPaperSizesAndOrientation() {
        let a4 = PaperSize.a4.dimensionsPoints
        XCTAssertEqual(a4.width, 210 * 72 / 25.4, accuracy: 0.01)
        XCTAssertEqual(a4.height, 297 * 72 / 25.4, accuracy: 0.01)
        let letter = PaperSize.usLetter.dimensionsPoints
        XCTAssertEqual(letter.width, 612, accuracy: 0.01)
        XCTAssertEqual(letter.height, 792, accuracy: 0.01)
        let a5 = PaperSize.a5.dimensionsPoints
        XCTAssertEqual(a5.width, 148 * 72 / 25.4, accuracy: 0.01)
        XCTAssertEqual(a5.height, 210 * 72 / 25.4, accuracy: 0.01)
        let legal = PaperSize.legal.dimensionsPoints
        XCTAssertEqual(legal.width, 612, accuracy: 0.01)
        XCTAssertEqual(legal.height, 1008, accuracy: 0.01)
        let landscape = CalendarSheetLayout.make(rowCount: 5, configuration: CalendarSheetConfiguration(paperSize: .usLetter, orientation: .landscape))
        XCTAssertEqual(landscape.paperBounds.width, 792, accuracy: 0.01)
        XCTAssertEqual(landscape.paperBounds.height, 612, accuracy: 0.01)
    }

    func testLayoutFramesAndWarningsStayNonnegative() throws {
        let grid = MonthGrid(month: try XCTUnwrap(CivilMonth(year: 2027, month: 1)))
        let layout = CalendarSheetLayout.make(for: grid, configuration: CalendarSheetConfiguration(notesHeight: 100))
        XCTAssertEqual(layout.dayCellFrames.count, grid.cells.count)
        XCTAssertTrue(layout.dayCellFrames.allSatisfy { $0.width >= 0 && $0.height >= 0 })
        XCTAssertGreaterThan(layout.printableBounds.width, 0)
        XCTAssertGreaterThan(layout.gridFrame.height, 0)
        let badMargins = CalendarSheetLayout.make(rowCount: 6, configuration: CalendarSheetConfiguration(margins: PaperMargins(top: -1, right: -1, bottom: -1, left: -1)))
        XCTAssertTrue(badMargins.warnings.contains(.invalidMargins))
        let consumed = CalendarSheetLayout.make(rowCount: 6, configuration: CalendarSheetConfiguration(notesHeight: 10_000))
        XCTAssertTrue(consumed.warnings.contains(.notesRegionConsumesGrid))
        XCTAssertTrue(consumed.gridFrame.height >= 0)
    }

    func testBlankGridHasNoDatesAndAcceptsOnlyFiveOrSixRows() throws {
        XCTAssertNil(BlankGrid(rows: 4))
        XCTAssertNil(BlankGrid(rows: 7))
        let five = try XCTUnwrap(BlankCalendarSheet(rows: 5))
        let six = try XCTUnwrap(BlankCalendarSheet(rows: 6))
        XCTAssertEqual(five.grid.rowCount * five.grid.columnCount, 35)
        XCTAssertEqual(six.grid.rowCount * six.grid.columnCount, 42)
        XCTAssertEqual(five.layout.dayCellFrames.count, 35)
        XCTAssertEqual(six.layout.dayCellFrames.count, 42)
    }

    func testReferenceURLMappingIsCanonical() throws {
        XCTAssertEqual(HumanReadableReference.homepageURL.absoluteString, "https://www.betacalendars.com/")
        XCTAssertEqual(HumanReadableReference.blankCalendarURL.absoluteString, "https://www.betacalendars.com/blank-calendar")
        for month in 1...12 {
            let reference = try XCTUnwrap(HumanReadableReference.reference(forMonth: month))
            let slug = CivilMonth.monthNames[month - 1].lowercased()
            XCTAssertEqual(reference.url.absoluteString, "https://www.betacalendars.com/\(slug)-calendar.html")
            XCTAssertFalse(reference.url.absoluteString.contains("?"))
        }
        XCTAssertNil(HumanReadableReference.reference(forMonth: 0))
        XCTAssertNil(HumanReadableReference.reference(forMonth: 13))
        XCTAssertEqual(HumanReadableReference.allCases.count, 14)
    }

    func testCodableModelsPreserveTheirInvariants() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let original = MonthGrid(month: try XCTUnwrap(CivilMonth(year: 2027, month: 2)), weekStart: .monday, mode: .fixedSixWeeks, adjacentDayPolicy: .included)
        XCTAssertEqual(try decoder.decode(MonthGrid.self, from: encoder.encode(original)), original)
        XCTAssertThrowsError(try decoder.decode(CivilMonth.self, from: Data("{\"year\":2027,\"month\":13}".utf8)))
        XCTAssertThrowsError(try decoder.decode(BlankGrid.self, from: Data("{\"rowCount\":4}".utf8)))
    }

    func testTimezoneMatrixDoesNotChangeCivilResults() throws {
        let month = try XCTUnwrap(CivilMonth(year: 2027, month: 1))
        let expected = MonthGrid(month: month, weekStart: .sunday, mode: .fixedSixWeeks, adjacentDayPolicy: .included)
        let oldDefault = NSTimeZone.default
        defer { NSTimeZone.default = oldDefault }
        for identifier in ["UTC", "Europe/Istanbul", "America/New_York", "Asia/Tokyo"] {
            NSTimeZone.default = try XCTUnwrap(TimeZone(identifier: identifier))
            XCTAssertEqual(MonthGrid(month: month, weekStart: .sunday, mode: .fixedSixWeeks, adjacentDayPolicy: .included), expected, identifier)
        }
    }

    #if canImport(PDFKit)
    func testPDFPageSizesAndYearPageCount() throws {
        let month = try XCTUnwrap(CivilMonth(year: 2027, month: 1))
        let a4Data = try CalendarPDFRenderer.render(monthGrid: MonthGrid(month: month))
        let a4 = try XCTUnwrap(PDFDocument(data: a4Data)?.page(at: 0))
        XCTAssertEqual(a4.bounds(for: .mediaBox).width, CGFloat(210 * 72 / 25.4), accuracy: 0.1)
        XCTAssertEqual(a4.bounds(for: .mediaBox).height, CGFloat(297 * 72 / 25.4), accuracy: 0.1)
        var letterConfiguration = CalendarSheetConfiguration(paperSize: .usLetter, orientation: .landscape)
        letterConfiguration.notesHeight = 80
        let letterData = try CalendarPDFRenderer.render(monthGrid: MonthGrid(month: month), configuration: letterConfiguration)
        let letter = try XCTUnwrap(PDFDocument(data: letterData)?.page(at: 0))
        XCTAssertEqual(letter.bounds(for: .mediaBox).width, 792, accuracy: 0.1)
        XCTAssertEqual(letter.bounds(for: .mediaBox).height, 612, accuracy: 0.1)
        let yearData = try CalendarPDFRenderer.renderYear(2027)
        XCTAssertEqual(PDFDocument(data: yearData)?.pageCount, 12)
        let blankData = try CalendarPDFRenderer.render(blankSheet: BlankCalendarSheet(rows: 5)!)
        XCTAssertEqual(PDFDocument(data: blankData)?.pageCount, 1)
    }
    #endif
}
