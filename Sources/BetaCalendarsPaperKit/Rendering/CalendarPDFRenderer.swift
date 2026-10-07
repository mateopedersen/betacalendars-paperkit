#if canImport(CoreGraphics) && canImport(CoreText)
import CoreGraphics
import CoreText
import Foundation

public struct CalendarPDFStyle: Sendable, Hashable {
    public var text: PDFColor
    public var grid: PDFColor
    public var paper: PDFColor
    public var titlePointSize: Double
    public var bodyPointSize: Double

    public init(text: PDFColor = .black, grid: PDFColor = PDFColor(red: 0.55, green: 0.55, blue: 0.55), paper: PDFColor = .white, titlePointSize: Double = 18, bodyPointSize: Double = 9) {
        self.text = text; self.grid = grid; self.paper = paper
        self.titlePointSize = titlePointSize; self.bodyPointSize = bodyPointSize
    }

    public static let standard = CalendarPDFStyle()
}

public struct PDFColor: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    public static let black = PDFColor(red: 0, green: 0, blue: 0)
    public static let white = PDFColor(red: 1, green: 1, blue: 1)
}

public enum CalendarPDFError: Error, Equatable {
    case invalidLayout
    case cannotCreatePDF
}

/// Generates deterministic vector PDFs using Core Graphics and Core Text.
public enum CalendarPDFRenderer {
    public static func render(monthGrid: MonthGrid, configuration: CalendarSheetConfiguration = CalendarSheetConfiguration(), style: CalendarPDFStyle = .standard) throws -> Data {
        try renderPages([(monthGrid, configuration)], style: style)
    }

    public static func renderYear(_ year: Int, configuration: CalendarSheetConfiguration = CalendarSheetConfiguration(), style: CalendarPDFStyle = .standard) throws -> Data {
        guard (1...9999).contains(year) else { throw CalendarPDFError.invalidLayout }
        let pages = (1...12).compactMap { month -> (MonthGrid, CalendarSheetConfiguration)? in
            guard let civil = CivilMonth(year: year, month: month) else { return nil }
            let grid = MonthGrid(month: civil, weekStart: configuration.weekStart, mode: configuration.gridMode, adjacentDayPolicy: configuration.adjacentDayPolicy)
            return (grid, configuration)
        }
        return try renderPages(pages, style: style)
    }

    public static func render(blankSheet: BlankCalendarSheet, style: CalendarPDFStyle = .standard) throws -> Data {
        let page = blankSheet.configuration
        let layout = blankSheet.layout
        guard isUsable(layout) else { throw CalendarPDFError.invalidLayout }
        return try makePDF(pageSize: layout.paperBounds, pageCount: 1) { context, _ in
            paintBlank(context, layout: layout, grid: blankSheet.grid, configuration: page, style: style)
        }
    }

    private static func renderPages(_ pages: [(MonthGrid, CalendarSheetConfiguration)], style: CalendarPDFStyle) throws -> Data {
        guard !pages.isEmpty else { throw CalendarPDFError.invalidLayout }
        let layouts = pages.map { (grid: $0.0, configuration: $0.1, layout: CalendarSheetLayout.make(for: $0.0, configuration: $0.1)) }
        guard layouts.allSatisfy({ isUsable($0.layout) }) else { throw CalendarPDFError.invalidLayout }
        return try makePDF(pageSize: layouts[0].layout.paperBounds, pageCount: layouts.count) { context, index in
            let page = layouts[index]
            paintMonth(context, grid: page.grid, layout: page.layout, configuration: page.configuration, style: style)
        }
    }

    private static func makePDF(pageSize: PaperRect, pageCount: Int, draw: (CGContext, Int) -> Void) throws -> Data {
        let output = NSMutableData()
        guard let consumer = CGDataConsumer(data: output as CFMutableData) else { throw CalendarPDFError.cannotCreatePDF }
        var mediaBox = CGRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { throw CalendarPDFError.cannotCreatePDF }
        for page in 0..<pageCount {
            context.beginPDFPage(nil)
            draw(context, page)
            context.endPDFPage()
        }
        context.closePDF()
        return output as Data
    }

    private static func paintMonth(_ context: CGContext, grid: MonthGrid, layout: CalendarSheetLayout, configuration: CalendarSheetConfiguration, style: CalendarPDFStyle) {
        paintPaper(context, layout: layout, color: style.paper)
        drawText("\(grid.month.englishName) \(grid.month.year)", context: context, frame: layout.titleFrame, paperHeight: layout.paperBounds.height, size: style.titlePointSize, color: style.text, alignment: .center)
        let weekdayWidth = layout.weekdayHeaderFrame.width / 7
        for column in 0..<7 {
            let weekday = Weekday(rawValue: (grid.weekStart.rawValue + column) % 7)!
            let frame = PaperRect(x: layout.weekdayHeaderFrame.x + Double(column) * weekdayWidth, y: layout.weekdayHeaderFrame.y, width: weekdayWidth, height: layout.weekdayHeaderFrame.height)
            drawText(weekday.shortName, context: context, frame: frame, paperHeight: layout.paperBounds.height, size: style.bodyPointSize, color: style.text, alignment: .center)
        }
        drawGrid(context, layout: layout, style: style)
        for cell in grid.cells {
            guard cell.day != nil, layout.dayCellFrames.indices.contains(cell.row * 7 + cell.column) else { continue }
            let frame = layout.dayCellFrames[cell.row * 7 + cell.column]
            let color = cell.relation == .currentMonth ? style.text : PDFColor(red: style.text.red, green: style.text.green, blue: style.text.blue, alpha: 0.4)
            drawText(String(cell.day!), context: context, frame: frame, paperHeight: layout.paperBounds.height, size: style.bodyPointSize, color: color, alignment: .left, inset: configuration.cellPadding + 2)
        }
        drawNotes(context, layout: layout, style: style)
    }

    private static func paintBlank(_ context: CGContext, layout: CalendarSheetLayout, grid: BlankGrid, configuration: CalendarSheetConfiguration, style: CalendarPDFStyle) {
        paintPaper(context, layout: layout, color: style.paper)
        let weekdayWidth = layout.weekdayHeaderFrame.width / 7
        for column in 0..<7 {
            let weekday = Weekday(rawValue: (configuration.weekStart.rawValue + column) % 7)!
            let frame = PaperRect(x: layout.weekdayHeaderFrame.x + Double(column) * weekdayWidth, y: layout.weekdayHeaderFrame.y, width: weekdayWidth, height: layout.weekdayHeaderFrame.height)
            drawText(weekday.shortName, context: context, frame: frame, paperHeight: layout.paperBounds.height, size: style.bodyPointSize, color: style.text, alignment: .center)
        }
        drawGrid(context, layout: layout, style: style)
        drawNotes(context, layout: layout, style: style)
        _ = grid
    }

    private static func paintPaper(_ context: CGContext, layout: CalendarSheetLayout, color: PDFColor) {
        context.saveGState()
        context.setFillColor(cgColor(color))
        context.fill(CGRect(x: 0, y: 0, width: layout.paperBounds.width, height: layout.paperBounds.height))
        context.restoreGState()
    }

    private static func drawGrid(_ context: CGContext, layout: CalendarSheetLayout, style: CalendarPDFStyle) {
        context.saveGState()
        context.setStrokeColor(cgColor(style.grid))
        context.setLineWidth(0.5)
        for column in 0...7 {
            let x = layout.gridFrame.x + layout.gridFrame.width * Double(column) / 7
            context.move(to: CGPoint(x: x, y: pdfY(layout.paperBounds, top: layout.gridFrame.y)))
            context.addLine(to: CGPoint(x: x, y: pdfY(layout.paperBounds, top: layout.gridFrame.maxY)))
        }
        for row in 0...layout.rowCount {
            let y = layout.gridFrame.y + layout.gridFrame.height * Double(row) / Double(layout.rowCount)
            context.move(to: CGPoint(x: layout.gridFrame.x, y: pdfY(layout.paperBounds, top: y)))
            context.addLine(to: CGPoint(x: layout.gridFrame.maxX, y: pdfY(layout.paperBounds, top: y)))
        }
        context.strokePath()
        context.restoreGState()
    }

    private static func drawNotes(_ context: CGContext, layout: CalendarSheetLayout, style: CalendarPDFStyle) {
        guard layout.notesFrame.height > 0 else { return }
        context.saveGState()
        context.setStrokeColor(cgColor(style.grid))
        context.setLineWidth(0.5)
        for line in 1...3 {
            let y = layout.notesFrame.y + layout.notesFrame.height * Double(line) / 4
            context.move(to: CGPoint(x: layout.notesFrame.x, y: pdfY(layout.paperBounds, top: y)))
            context.addLine(to: CGPoint(x: layout.notesFrame.maxX, y: pdfY(layout.paperBounds, top: y)))
        }
        context.strokePath()
        context.restoreGState()
    }

    private enum TextAlignment: Equatable { case left, center }

    private static func drawText(_ value: String, context: CGContext, frame: PaperRect, paperHeight: Double, size: Double, color: PDFColor, alignment: TextAlignment, inset: Double = 0) {
        let font = CTFontCreateWithName("Helvetica" as CFString, CGFloat(max(1, size)), nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): cgColor(color)
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: attributes))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, nil)
        let bounds = (width: lineWidth, ascent: Double(ascent), descent: Double(descent))
        let x = alignment == .center ? frame.x + (frame.width - bounds.width) / 2 : frame.x + inset
        let baselineFromTop = frame.y + (frame.height + bounds.ascent - bounds.descent) / 2
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: paperHeight - baselineFromTop)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func pdfY(_ paper: PaperRect, top: Double) -> Double { paper.height - top }

    private static func cgColor(_ color: PDFColor) -> CGColor {
        func clamp(_ value: Double) -> CGFloat { CGFloat(value.isFinite ? min(1, max(0, value)) : 0) }
        return CGColor(red: clamp(color.red), green: clamp(color.green), blue: clamp(color.blue), alpha: clamp(color.alpha))
    }

    private static func isUsable(_ layout: CalendarSheetLayout) -> Bool {
        guard layout.paperBounds.width > 0, layout.paperBounds.height > 0 else { return false }
        let fatal: Set<CalendarLayoutWarning> = [.invalidPaperSize, .invalidMargins, .insufficientPrintableWidth, .insufficientPrintableHeight, .notesRegionConsumesGrid]
        return layout.warnings.allSatisfy { !fatal.contains($0) }
    }
}
#endif
