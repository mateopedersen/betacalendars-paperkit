import Foundation

/// A validated Gregorian civil month, independent of timestamps and time zones.
public struct CivilMonth: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    public let year: Int
    public let month: Int

    public init?(year: Int, month: Int) {
        guard (1...9999).contains(year), (1...12).contains(month) else { return nil }
        self.year = year
        self.month = month
    }

    public var daysInMonth: Int {
        switch month {
        case 2: Self.isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }

    public static func isLeapYear(_ year: Int) -> Bool {
        year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
    }

    private enum CodingKeys: String, CodingKey { case year, month }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let year = try values.decode(Int.self, forKey: .year)
        let month = try values.decode(Int.self, forKey: .month)
        guard let valid = CivilMonth(year: year, month: month) else {
            throw DecodingError.dataCorruptedError(forKey: .month, in: values, debugDescription: "CivilMonth requires a year in 1...9999 and month in 1...12.")
        }
        self = valid
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(year, forKey: .year)
        try values.encode(month, forKey: .month)
    }

    public var previousMonth: CivilMonth? {
        month == 1 ? CivilMonth(year: year - 1, month: 12) : CivilMonth(year: year, month: month - 1)
    }

    public var nextMonth: CivilMonth? {
        month == 12 ? CivilMonth(year: year + 1, month: 1) : CivilMonth(year: year, month: month + 1)
    }

    public static func < (lhs: CivilMonth, rhs: CivilMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    public var description: String { "\(year)-\(String(format: "%02d", month))" }

    /// English month names keep the core deterministic; localized names can be supplied by a UI.
    public var englishName: String {
        Self.monthNames[month - 1]
    }

    public static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
}

/// A validated Gregorian civil date without a time-of-day or time zone.
public struct CivilDate: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    public let month: CivilMonth
    public let day: Int

    public init?(year: Int, month: Int, day: Int) {
        guard let civilMonth = CivilMonth(year: year, month: month), (1...civilMonth.daysInMonth).contains(day) else { return nil }
        self.month = civilMonth
        self.day = day
    }

    public init?(month: CivilMonth, day: Int) {
        guard (1...month.daysInMonth).contains(day) else { return nil }
        self.month = month
        self.day = day
    }

    public var year: Int { month.year }
    public var monthNumber: Int { month.month }
    public var description: String { "\(month)-\(String(format: "%02d", day))" }

    private enum CodingKeys: String, CodingKey { case month, day }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let month = try values.decode(CivilMonth.self, forKey: .month)
        let day = try values.decode(Int.self, forKey: .day)
        guard let valid = CivilDate(month: month, day: day) else {
            throw DecodingError.dataCorruptedError(forKey: .day, in: values, debugDescription: "Day is outside the selected civil month.")
        }
        self = valid
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(month, forKey: .month)
        try values.encode(day, forKey: .day)
    }

    public static func < (lhs: CivilDate, rhs: CivilDate) -> Bool {
        (lhs.year, lhs.monthNumber, lhs.day) < (rhs.year, rhs.monthNumber, rhs.day)
    }
}

/// ISO-like Sunday-first ordinal numbering: Sunday is zero through Saturday six.
public enum Weekday: Int, CaseIterable, Sendable, Hashable, Codable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday

    public var englishName: String {
        ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][rawValue]
    }

    public var shortName: String {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][rawValue]
    }
}

public enum WeekStart: Int, CaseIterable, Sendable, Hashable, Codable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
    public var weekday: Weekday { Weekday(rawValue: rawValue)! }
}

public enum GridMode: Sendable, Hashable, Codable {
    case natural
    case fixedSixWeeks
}

public enum AdjacentDayPolicy: Sendable, Hashable, Codable {
    /// Adjacent-month positions are empty.
    case hidden
    /// Adjacent day numbers are shown without representing them as selectable dates.
    case placeholder
    /// Adjacent positions contain their actual civil dates.
    case included
}

public enum MonthRelation: Sendable, Hashable, Codable {
    case previousMonth, currentMonth, nextMonth
}

public struct CalendarCell: Sendable, Hashable {
    /// Nil for adjacent positions unless the grid uses `.included`.
    public let date: CivilDate?
    /// Nil for `.hidden` adjacent positions; otherwise the displayed day number.
    public let day: Int?
    public let row: Int
    public let column: Int
    public let weekday: Weekday
    public let relation: MonthRelation

    public var isPlaceholder: Bool { date == nil && day != nil }
}

public struct MonthGrid: Sendable, Hashable, Codable {
    public let month: CivilMonth
    public let weekStart: WeekStart
    public let mode: GridMode
    public let adjacentDayPolicy: AdjacentDayPolicy
    public let rows: [[CalendarCell]]

    public var cells: [CalendarCell] { rows.flatMap { $0 } }
    public var rowCount: Int { rows.count }

    private enum CodingKeys: String, CodingKey { case month, weekStart, mode, adjacentDayPolicy }

    public init(month: CivilMonth, weekStart: WeekStart = .sunday, mode: GridMode = .natural, adjacentDayPolicy: AdjacentDayPolicy = .hidden) {
        self.month = month
        self.weekStart = weekStart
        self.mode = mode
        self.adjacentDayPolicy = adjacentDayPolicy

        let firstWeekday = Self.weekday(year: month.year, month: month.month, day: 1)
        let leading = (firstWeekday.rawValue - weekStart.rawValue + 7) % 7
        let naturalRows = (leading + month.daysInMonth + 6) / 7
        let rowCount = mode == .fixedSixWeeks ? 6 : naturalRows
        let previousMonth = month.previousMonth
        let previousDays = previousMonth?.daysInMonth ?? 0
        var built: [[CalendarCell]] = []
        for row in 0..<rowCount {
            var line: [CalendarCell] = []
            for column in 0..<7 {
                let index = row * 7 + column
                let relative = index - leading + 1
                let weekday = Weekday(rawValue: (weekStart.rawValue + column) % 7)!
                let relation: MonthRelation
                let date: CivilDate?
                let day: Int?
                if relative < 1 {
                    relation = .previousMonth
                    let adjacentDay = previousDays + relative
                    date = adjacentDayPolicy == .included && adjacentDay > 0
                        ? previousMonth.flatMap { CivilDate(month: $0, day: adjacentDay) }
                        : nil
                    day = adjacentDayPolicy == .hidden || previousMonth == nil || adjacentDay < 1 ? nil : adjacentDay
                } else if relative > month.daysInMonth {
                    relation = .nextMonth
                    let adjacentDay = relative - month.daysInMonth
                    date = adjacentDayPolicy == .included ? month.nextMonth.flatMap { CivilDate(month: $0, day: adjacentDay) } : nil
                    day = adjacentDayPolicy == .hidden ? nil : adjacentDay
                } else {
                    relation = .currentMonth
                    date = CivilDate(month: month, day: relative)
                    day = relative
                }
                line.append(CalendarCell(date: date, day: day, row: row, column: column, weekday: weekday, relation: relation))
            }
            built.append(line)
        }
        self.rows = built
    }

    /// Gregorian weekday using an integer-only proleptic Gregorian calculation.
    private static func weekday(year: Int, month: Int, day: Int) -> Weekday {
        // Sakamoto's algorithm; callers provide validated civil components.
        let offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
        var y = year
        if month < 3 { y -= 1 }
        let sundayZero = (y + y / 4 - y / 100 + y / 400 + offsets[month - 1] + day) % 7
        return Weekday(rawValue: sundayZero)!
    }

    /// Decode only the month-grid inputs, then rebuild the derived cells so malformed serialized rows cannot enter the model.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            month: try values.decode(CivilMonth.self, forKey: .month),
            weekStart: try values.decode(WeekStart.self, forKey: .weekStart),
            mode: try values.decode(GridMode.self, forKey: .mode),
            adjacentDayPolicy: try values.decode(AdjacentDayPolicy.self, forKey: .adjacentDayPolicy)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(month, forKey: .month)
        try values.encode(weekStart, forKey: .weekStart)
        try values.encode(mode, forKey: .mode)
        try values.encode(adjacentDayPolicy, forKey: .adjacentDayPolicy)
    }
}
