import Foundation

public enum PaperOrientation: String, Sendable, Hashable, Codable {
    case portrait, landscape
}

/// Standard paper dimensions stored in typographic points (72 points per inch).
public enum PaperSize: Sendable, Hashable, Codable {
    case a4, usLetter, a5, legal
    case custom(widthPoints: Double, heightPoints: Double)

    public static func millimeters(_ value: Double) -> Double { value * 72 / 25.4 }
    public static func inches(_ value: Double) -> Double { value * 72 }

    public var dimensionsPoints: (width: Double, height: Double) {
        switch self {
        case .a4: (Self.millimeters(210), Self.millimeters(297))
        case .usLetter: (Self.inches(8.5), Self.inches(11))
        case .a5: (Self.millimeters(148), Self.millimeters(210))
        case .legal: (Self.inches(8.5), Self.inches(14))
        case let .custom(width, height): (width, height)
        }
    }
}

public struct PaperMargins: Sendable, Hashable, Codable {
    public var top: Double
    public var right: Double
    public var bottom: Double
    public var left: Double

    public init(top: Double = 36, right: Double = 36, bottom: Double = 36, left: Double = 36) {
        self.top = top; self.right = right; self.bottom = bottom; self.left = left
    }

    public static let halfInch = PaperMargins(top: 36, right: 36, bottom: 36, left: 36)
}

public struct PaperRect: Sendable, Hashable, Codable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }

    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
}

public struct CalendarSheetConfiguration: Sendable, Hashable, Codable {
    public var paperSize: PaperSize
    public var orientation: PaperOrientation
    public var margins: PaperMargins
    public var weekStart: WeekStart
    public var gridMode: GridMode
    public var adjacentDayPolicy: AdjacentDayPolicy
    public var titleHeight: Double
    public var weekdayHeaderHeight: Double
    public var notesHeight: Double
    public var outerSpacing: Double
    public var cellPadding: Double
    public var minimumCellSize: Double

    public init(
        paperSize: PaperSize = .a4,
        orientation: PaperOrientation = .portrait,
        margins: PaperMargins = .halfInch,
        weekStart: WeekStart = .sunday,
        gridMode: GridMode = .natural,
        adjacentDayPolicy: AdjacentDayPolicy = .hidden,
        titleHeight: Double = 44,
        weekdayHeaderHeight: Double = 24,
        notesHeight: Double = 0,
        outerSpacing: Double = 8,
        cellPadding: Double = 2,
        minimumCellSize: Double = 12
    ) {
        self.paperSize = paperSize; self.orientation = orientation; self.margins = margins
        self.weekStart = weekStart; self.gridMode = gridMode; self.adjacentDayPolicy = adjacentDayPolicy
        self.titleHeight = titleHeight; self.weekdayHeaderHeight = weekdayHeaderHeight
        self.notesHeight = notesHeight; self.outerSpacing = outerSpacing
        self.cellPadding = cellPadding; self.minimumCellSize = minimumCellSize
    }
}

public enum CalendarLayoutWarning: Sendable, Hashable, Codable {
    case invalidPaperSize
    case invalidMargins
    case insufficientPrintableWidth
    case insufficientPrintableHeight
    case cellTooSmall
    case notesRegionConsumesGrid
}

public struct CalendarSheetLayout: Sendable, Hashable, Codable {
    public let paperBounds: PaperRect
    public let printableBounds: PaperRect
    public let titleFrame: PaperRect
    public let weekdayHeaderFrame: PaperRect
    public let gridFrame: PaperRect
    public let notesFrame: PaperRect
    public let dayCellFrames: [PaperRect]
    public let rowCount: Int
    public let warnings: [CalendarLayoutWarning]

    public static func make(for grid: MonthGrid, configuration: CalendarSheetConfiguration) -> CalendarSheetLayout {
        make(rowCount: grid.rowCount, configuration: configuration)
    }

    public static func make(rowCount requestedRows: Int, configuration c: CalendarSheetConfiguration) -> CalendarSheetLayout {
        let raw = c.paperSize.dimensionsPoints
        let validPaper = raw.width.isFinite && raw.height.isFinite && raw.width > 0 && raw.height > 0
        let baseWidth = validPaper ? raw.width : 0
        let baseHeight = validPaper ? raw.height : 0
        let width = c.orientation == .portrait ? min(baseWidth, baseHeight) : max(baseWidth, baseHeight)
        let height = c.orientation == .portrait ? max(baseWidth, baseHeight) : min(baseWidth, baseHeight)
        var warnings: [CalendarLayoutWarning] = []
        func addWarning(_ warning: CalendarLayoutWarning) {
            if !warnings.contains(warning) { warnings.append(warning) }
        }
        if !validPaper { addWarning(.invalidPaperSize) }

        let marginValues = [c.margins.top, c.margins.right, c.margins.bottom, c.margins.left]
        let marginsValid = marginValues.allSatisfy { $0.isFinite && $0 >= 0 }
        if !marginsValid { addWarning(.invalidMargins) }
        let top = marginsValid ? c.margins.top : 0
        let right = marginsValid ? c.margins.right : 0
        let bottom = marginsValid ? c.margins.bottom : 0
        let left = marginsValid ? c.margins.left : 0
        let printableWidth = max(0, width - left - right)
        let printableHeight = max(0, height - top - bottom)
        if printableWidth <= 0 { addWarning(.insufficientPrintableWidth) }
        if printableHeight <= 0 { addWarning(.insufficientPrintableHeight) }
        let printable = PaperRect(x: left, y: top, width: printableWidth, height: printableHeight)

        let titleHeight = nonnegative(c.titleHeight)
        let headerHeight = nonnegative(c.weekdayHeaderHeight)
        let notesHeight = nonnegative(c.notesHeight)
        let spacing = nonnegative(c.outerSpacing)
        let rowCount = max(1, requestedRows)
        let gridX = printable.x
        let gridY = printable.y + min(titleHeight, printable.height) + headerHeight + spacing
        let gridWidth = printable.width
        let gridBottom = printable.maxY - notesHeight - (notesHeight > 0 ? spacing : 0)
        let gridHeight = max(0, gridBottom - gridY)
        if gridHeight == 0 { addWarning(.notesRegionConsumesGrid) }
        if printable.height < titleHeight + headerHeight + notesHeight + spacing { addWarning(.insufficientPrintableHeight) }
        let cellWidth = gridWidth / 7
        let cellHeight = gridHeight / Double(rowCount)
        let pad = nonnegative(c.cellPadding)
        if !c.minimumCellSize.isFinite || c.minimumCellSize < 0 || cellWidth - 2 * pad < c.minimumCellSize || cellHeight - 2 * pad < c.minimumCellSize {
            addWarning(.cellTooSmall)
        }
        var cellFrames: [PaperRect] = []
        for row in 0..<rowCount {
            for column in 0..<7 {
                cellFrames.append(PaperRect(
                    x: gridX + Double(column) * cellWidth + min(pad, cellWidth / 2),
                    y: gridY + Double(row) * cellHeight + min(pad, cellHeight / 2),
                    width: max(0, cellWidth - 2 * pad),
                    height: max(0, cellHeight - 2 * pad)
                ))
            }
        }
        let title = PaperRect(x: printable.x, y: printable.y, width: printable.width, height: min(titleHeight, printable.height))
        let header = PaperRect(x: printable.x, y: title.maxY, width: printable.width, height: min(headerHeight, max(0, printable.maxY - title.maxY)))
        let notes = PaperRect(x: printable.x, y: max(printable.y, printable.maxY - notesHeight), width: printable.width, height: min(notesHeight, printable.height))
        let grid = PaperRect(x: gridX, y: gridY, width: gridWidth, height: gridHeight)
        return CalendarSheetLayout(
            paperBounds: PaperRect(x: 0, y: 0, width: width, height: height), printableBounds: printable,
            titleFrame: title, weekdayHeaderFrame: header, gridFrame: grid, notesFrame: notes,
            dayCellFrames: cellFrames, rowCount: rowCount, warnings: warnings
        )
    }

    private static func nonnegative(_ value: Double) -> Double { value.isFinite ? max(0, value) : 0 }
}

public struct BlankGrid: Sendable, Hashable, Codable {
    public let rowCount: Int
    public let columnCount: Int

    public init?(rows: Int) {
        guard rows == 5 || rows == 6 else { return nil }
        self.rowCount = rows
        self.columnCount = 7
    }

    private enum CodingKeys: String, CodingKey { case rowCount }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rows = try values.decode(Int.self, forKey: .rowCount)
        guard let grid = BlankGrid(rows: rows) else {
            throw DecodingError.dataCorruptedError(forKey: .rowCount, in: values, debugDescription: "A blank calendar grid must have five or six rows.")
        }
        self = grid
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(rowCount, forKey: .rowCount)
    }
}

public struct BlankCalendarSheet: Sendable, Hashable, Codable {
    public let grid: BlankGrid
    public let configuration: CalendarSheetConfiguration

    public init?(rows: Int, configuration: CalendarSheetConfiguration = CalendarSheetConfiguration()) {
        guard let grid = BlankGrid(rows: rows) else { return nil }
        self.grid = grid
        self.configuration = configuration
    }

    public var layout: CalendarSheetLayout { CalendarSheetLayout.make(rowCount: grid.rowCount, configuration: configuration) }

    private enum CodingKeys: String, CodingKey { case grid, configuration }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let grid = try values.decode(BlankGrid.self, forKey: .grid)
        self.grid = grid
        self.configuration = try values.decode(CalendarSheetConfiguration.self, forKey: .configuration)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(grid, forKey: .grid)
        try values.encode(configuration, forKey: .configuration)
    }
}
