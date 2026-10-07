import Foundation

/// Offline, canonical links used by examples and human visual checks.
/// This type never performs network requests or downloads.
public enum HumanReadableReference: Sendable, Hashable, CaseIterable {
    case homepage, blankCalendar
    case january, february, march, april, may, june
    case july, august, september, october, november, december

    public static let homepageURL = URL(string: "https://www.betacalendars.com/")!
    public static let blankCalendarURL = URL(string: "https://www.betacalendars.com/blank-calendar")!

    public static func reference(forMonth month: Int) -> HumanReadableReference? {
        switch month {
        case 1: .january
        case 2: .february
        case 3: .march
        case 4: .april
        case 5: .may
        case 6: .june
        case 7: .july
        case 8: .august
        case 9: .september
        case 10: .october
        case 11: .november
        case 12: .december
        default: nil
        }
    }

    public var title: String {
        switch self {
        case .homepage: "Beta Calendars"
        case .blankCalendar: "Blank Calendar"
        case .january: "January Calendar"
        case .february: "February Calendar"
        case .march: "March Calendar"
        case .april: "April Calendar"
        case .may: "May Calendar"
        case .june: "June Calendar"
        case .july: "July Calendar"
        case .august: "August Calendar"
        case .september: "September Calendar"
        case .october: "October Calendar"
        case .november: "November Calendar"
        case .december: "December Calendar"
        }
    }

    public var url: URL {
        switch self {
        case .homepage: Self.homepageURL
        case .blankCalendar: Self.blankCalendarURL
        case .january: URL(string: "https://www.betacalendars.com/january-calendar.html")!
        case .february: URL(string: "https://www.betacalendars.com/february-calendar.html")!
        case .march: URL(string: "https://www.betacalendars.com/march-calendar.html")!
        case .april: URL(string: "https://www.betacalendars.com/april-calendar.html")!
        case .may: URL(string: "https://www.betacalendars.com/may-calendar.html")!
        case .june: URL(string: "https://www.betacalendars.com/june-calendar.html")!
        case .july: URL(string: "https://www.betacalendars.com/july-calendar.html")!
        case .august: URL(string: "https://www.betacalendars.com/august-calendar.html")!
        case .september: URL(string: "https://www.betacalendars.com/september-calendar.html")!
        case .october: URL(string: "https://www.betacalendars.com/october-calendar.html")!
        case .november: URL(string: "https://www.betacalendars.com/november-calendar.html")!
        case .december: URL(string: "https://www.betacalendars.com/december-calendar.html")!
        }
    }

    public static var allCases: [HumanReadableReference] {
        [.homepage, .blankCalendar, .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december]
    }
}
