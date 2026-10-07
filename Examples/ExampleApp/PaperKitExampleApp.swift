#if canImport(SwiftUI)
import BetaCalendarsPaperKit
import SwiftUI

@main
struct PaperKitExampleApp: App {
    var body: some Scene {
        WindowGroup { PaperKitExampleView() }
    }
}

struct PaperKitExampleView: View {
    @State private var weekStart: WeekStart = .sunday
    @State private var fixedSixWeeks = false
    @State private var selectedPaper = 0

    private var configuration: CalendarSheetConfiguration {
        CalendarSheetConfiguration(
            paperSize: selectedPaper == 0 ? .a4 : .usLetter,
            orientation: selectedPaper == 0 ? .portrait : .landscape,
            weekStart: weekStart,
            gridMode: fixedSixWeeks ? .fixedSixWeeks : .natural,
            adjacentDayPolicy: .placeholder,
            notesHeight: selectedPaper == 0 ? 90 : 60
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Preview controls") {
                    Picker("Week starts", selection: $weekStart) {
                        ForEach(WeekStart.allCases, id: \.self) { Text($0.weekday.englishName).tag($0) }
                    }
                    Toggle("Fixed six-week grid", isOn: $fixedSixWeeks)
                    Picker("Paper", selection: $selectedPaper) {
                        Text("A4 portrait").tag(0)
                        Text("US Letter landscape").tag(1)
                    }
                    .pickerStyle(.segmented)
                }
                Section("January 2027") {
                    PrintableMonthView(
                        grid: MonthGrid(month: CivilMonth(year: 2027, month: 1)!, weekStart: weekStart,
                                        mode: fixedSixWeeks ? .fixedSixWeeks : .natural, adjacentDayPolicy: .placeholder),
                        configuration: configuration
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                Section("February 2027") {
                    PrintableMonthView(
                        grid: MonthGrid(month: CivilMonth(year: 2027, month: 2)!, weekStart: weekStart,
                                        mode: fixedSixWeeks ? .fixedSixWeeks : .natural, adjacentDayPolicy: .placeholder),
                        configuration: configuration
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                Section("Undated planner") {
                    BlankCalendarView(sheet: BlankCalendarSheet(rows: 5, configuration: configuration)!)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                }
            }
            .navigationTitle("PaperKit Example")
        }
    }
}
#else
import Foundation
@main enum PaperKitExampleApp {
    static func main() { print("PaperKitExample requires SwiftUI on iOS 15 or macOS 12 or later.") }
}
#endif
