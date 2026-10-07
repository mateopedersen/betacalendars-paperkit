#if canImport(SwiftUI)
import SwiftUI

public struct CalendarSheetStyle: Sendable {
    public var textColor: Color
    public var adjacentDayColor: Color
    public var weekendColor: Color
    public var gridColor: Color
    public var weekendFill: Color
    public var titleFont: Font
    public var weekdayFont: Font
    public var dayFont: Font
    public var showsGridLines: Bool

    public init(
        textColor: Color = .primary,
        adjacentDayColor: Color = .secondary,
        weekendColor: Color = .primary,
        gridColor: Color = .secondary.opacity(0.35),
        weekendFill: Color = .clear,
        titleFont: Font = .title2,
        weekdayFont: Font = .caption.weight(.semibold),
        dayFont: Font = .body,
        showsGridLines: Bool = true
    ) {
        self.textColor = textColor; self.adjacentDayColor = adjacentDayColor
        self.weekendColor = weekendColor; self.gridColor = gridColor; self.weekendFill = weekendFill
        self.titleFont = titleFont; self.weekdayFont = weekdayFont; self.dayFont = dayFont
        self.showsGridLines = showsGridLines
    }

    public static let standard = CalendarSheetStyle()
}

/// SwiftUI rendering for a precomputed month grid and paper layout.
public struct PrintableMonthView: View {
    public let grid: MonthGrid
    public let configuration: CalendarSheetConfiguration
    public let style: CalendarSheetStyle

    public init(grid: MonthGrid, configuration: CalendarSheetConfiguration = CalendarSheetConfiguration(), style: CalendarSheetStyle = .standard) {
        self.grid = grid; self.configuration = configuration; self.style = style
    }

    public var body: some View {
        let layout = CalendarSheetLayout.make(for: grid, configuration: configuration)
        VStack(spacing: 0) {
            Text("\(grid.month.englishName) \(grid.month.year)")
                .font(style.titleFont).foregroundStyle(style.textColor)
                .frame(maxWidth: .infinity, minHeight: layout.titleFrame.height, alignment: .center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("\(grid.month.englishName) \(grid.month.year) calendar")
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { column in
                    let weekday = Weekday(rawValue: (grid.weekStart.rawValue + column) % 7)!
                    Text(weekday.shortName).font(style.weekdayFont).foregroundStyle(style.textColor)
                        .frame(maxWidth: .infinity, minHeight: layout.weekdayHeaderFrame.height)
                }
            }
            if style.showsGridLines { Rectangle().fill(style.gridColor).frame(height: 1) }
            VStack(spacing: 0) {
                ForEach(Array(grid.rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(row, id: \.column) { cell in
                            cellView(cell)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if configuration.notesHeight > 0 {
                NotesLines(count: 3, color: style.gridColor)
                    .frame(height: layout.notesFrame.height)
            }
        }
        .padding(.top, configuration.margins.top)
        .padding(.horizontal, configuration.margins.left)
        .padding(.bottom, configuration.margins.bottom)
        .aspectRatio(paperAspectRatio, contentMode: .fit)
        .background(.background)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private func cellView(_ cell: CalendarCell) -> some View {
        let color = cell.relation == .currentMonth ? style.textColor : style.adjacentDayColor
        Text(cell.day.map { String($0) } ?? "")
            .font(style.dayFont)
            .foregroundStyle(cell.relation == .currentMonth && (cell.weekday == .sunday || cell.weekday == .saturday) ? style.weekendColor : color)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(configuration.cellPadding)
            .background((cell.weekday == .sunday || cell.weekday == .saturday) ? style.weekendFill : .clear)
            .overlay(alignment: .bottom) { if style.showsGridLines { Rectangle().fill(style.gridColor).frame(height: 0.5) } }
            .overlay(alignment: .trailing) { if style.showsGridLines { Rectangle().fill(style.gridColor).frame(width: 0.5) } }
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel(for: cell))
    }

    private func accessibilityLabel(for cell: CalendarCell) -> String {
        guard let day = cell.day else {
            let relation = cell.relation == .previousMonth ? "previous month" : "next month"
            return "Empty \(cell.weekday.englishName) cell, \(relation) relative to \(grid.month.englishName) \(grid.month.year)"
        }
        let relation = cell.relation == .currentMonth ? "current month" : (cell.relation == .previousMonth ? "previous month" : "next month")
        let dateLabel = cell.date?.description ?? "day \(day) in the \(relation)"
        return "\(cell.weekday.englishName), \(dateLabel), relative to \(grid.month.englishName) \(grid.month.year)"
    }

    private var paperAspectRatio: CGFloat {
        let size = configuration.paperSize.dimensionsPoints
        let w = configuration.orientation == .portrait ? min(size.width, size.height) : max(size.width, size.height)
        let h = configuration.orientation == .portrait ? max(size.width, size.height) : min(size.width, size.height)
        return CGFloat(w / max(h, 1))
    }
}

/// An undated planning grid with no synthetic date values.
public struct BlankCalendarView: View {
    public let sheet: BlankCalendarSheet
    public let style: CalendarSheetStyle

    public init(sheet: BlankCalendarSheet, style: CalendarSheetStyle = .standard) {
        self.sheet = sheet; self.style = style
    }

    public var body: some View {
        let layout = sheet.layout
        VStack(spacing: 0) {
            Color.clear.frame(height: layout.titleFrame.height)
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { column in
                    let weekday = Weekday(rawValue: (sheet.configuration.weekStart.rawValue + column) % 7)!
                    Text(weekday.shortName).font(style.weekdayFont).frame(maxWidth: .infinity, minHeight: layout.weekdayHeaderFrame.height)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(0..<(sheet.grid.rowCount * 7), id: \.self) { _ in
                    Rectangle().fill(.clear)
                        .frame(minHeight: max(20, layout.gridFrame.height / Double(sheet.grid.rowCount)))
                        .overlay { if style.showsGridLines { Rectangle().stroke(style.gridColor, lineWidth: 0.5) } }
                        .accessibilityLabel("Empty planning cell")
                }
            }
            .accessibilityLabel("Blank calendar grid, \(sheet.grid.rowCount) weeks")
        }
        .padding(.horizontal, sheet.configuration.margins.left)
        .padding(.top, sheet.configuration.margins.top)
        .padding(.bottom, sheet.configuration.margins.bottom)
        .aspectRatio(aspectRatio, contentMode: .fit)
        .background(.background)
    }

    private var aspectRatio: CGFloat {
        let size = sheet.configuration.paperSize.dimensionsPoints
        return CGFloat(size.width / max(size.height, 1))
    }
}

private struct NotesLines: View {
    let count: Int
    let color: Color
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { _ in Rectangle().fill(color).frame(height: 0.5) }
        }
    }
}

#endif
