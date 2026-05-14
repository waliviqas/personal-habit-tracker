import SwiftUI
import SwiftData

enum CalendarMode {
    case week, month, year
}

struct CalendarView: View {
    @State private var mode: CalendarMode = .week
    @State private var referenceDate = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerBar

                    switch mode {
                    case .week:
                        WeekCalendar(referenceDate: $referenceDate)
                    case .month:
                        MonthCalendar(referenceDate: $referenceDate)
                    case .year:
                        YearCalendar(referenceDate: $referenceDate) { selected in
                            referenceDate = selected
                            mode = .month
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        referenceDate = Date()
                        mode = .week
                    }
                    .foregroundColor(Theme.accent)
                }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button { goBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(Theme.primaryText)
            }
            Spacer()
            Button { zoomOut() } label: {
                HStack(spacing: 6) {
                    Text(headerTitle)
                        .font(.headline)
                        .foregroundColor(Theme.primaryText)
                    if mode != .year {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(Theme.secondaryText)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button { goForward() } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(Theme.primaryText)
            }
        }
        .padding()
    }

    private var headerTitle: String {
        let cal = Calendar.current
        switch mode {
        case .week:
            let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate))!
            let end = cal.date(byAdding: .day, value: 6, to: start)!
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return "\(f.string(from: start)) – \(f.string(from: end))"
        case .month:
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f.string(from: referenceDate)
        case .year:
            let f = DateFormatter()
            f.dateFormat = "yyyy"
            return f.string(from: referenceDate)
        }
    }

    private func zoomOut() {
        switch mode {
        case .week: mode = .month
        case .month: mode = .year
        case .year: break
        }
    }

    private func goBack() {
        let cal = Calendar.current
        switch mode {
        case .week:
            referenceDate = cal.date(byAdding: .weekOfYear, value: -1, to: referenceDate)!
        case .month:
            referenceDate = cal.date(byAdding: .month, value: -1, to: referenceDate)!
        case .year:
            referenceDate = cal.date(byAdding: .year, value: -1, to: referenceDate)!
        }
    }

    private func goForward() {
        let cal = Calendar.current
        switch mode {
        case .week:
            referenceDate = cal.date(byAdding: .weekOfYear, value: 1, to: referenceDate)!
        case .month:
            referenceDate = cal.date(byAdding: .month, value: 1, to: referenceDate)!
        case .year:
            referenceDate = cal.date(byAdding: .year, value: 1, to: referenceDate)!
        }
    }
}

struct WeekCalendar: View {
    @Binding var referenceDate: Date
    @Query private var habits: [Habit]
    @Query private var sprints: [Sprint]
    @Query private var journalEntries: [JournalEntry]
    private let calendar = Calendar.current

    private func hasJournalEntry(_ day: Date) -> Bool {
        journalEntries.contains { calendar.isDate($0.date, inSameDayAs: day) && !$0.content.isEmpty }
    }

    private var weekDays: [Date] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate))!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }

    var body: some View {
        List {
            ForEach(weekDays, id: \.self) { day in
                NavigationLink {
                    DayDetailView(date: day)
                } label: {
                    dayRow(day)
                }
                .listRowBackground(Theme.cardNavy)
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }

    private func dayRow(_ day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let isFuture = day > Date() && !isToday
        let scheduled = habits.filter { $0.isScheduled(on: day) }
        let allDone = !scheduled.isEmpty && scheduled.allSatisfy { $0.isCompleted(on: day) }
        let anyDone = scheduled.contains { $0.isCompleted(on: day) }
        let inSprint = SprintEngine.contains(day, in: sprints) != nil

        let dayLabelColor: Color = {
            if allDone { return .green }
            if isToday { return Theme.accent }
            if inSprint { return Theme.accent }
            return Theme.primaryText
        }()

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day, format: .dateTime.weekday(.wide))
                    .font(.subheadline)
                    .foregroundColor(dayLabelColor)
                    .bold(isToday || inSprint || allDone)
                HStack(spacing: 6) {
                    Text(day, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundColor(allDone ? .green.opacity(0.7) : Theme.secondaryText)
                    if hasJournalEntry(day) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            Spacer()
            statusIcon(scheduled: scheduled, allDone: allDone, anyDone: anyDone, isFuture: isFuture)
        }
        .padding(.vertical, 4)
    }
}

struct MonthCalendar: View {
    @Binding var referenceDate: Date
    @Query private var habits: [Habit]
    @Query private var sprints: [Sprint]
    @Query private var journalEntries: [JournalEntry]
    private let calendar = Calendar.current

    private func hasJournalEntry(_ day: Date) -> Bool {
        journalEntries.contains { calendar.isDate($0.date, inSameDayAs: day) && !$0.content.isEmpty }
    }

    private var dayLabels: [String] { ["M", "T", "W", "T", "F", "S", "S"] }

    private var cells: [Date?] {
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (firstWeekday + 5) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count

        var dates: [Date?] = Array(repeating: nil, count: leading)
        for i in 0..<daysInMonth {
            dates.append(calendar.date(byAdding: .day, value: i, to: firstOfMonth)!)
        }
        let trailing = (7 - dates.count % 7) % 7
        for _ in 0..<trailing { dates.append(nil) }
        return dates
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(dayLabels[i])
                            .font(.caption)
                            .foregroundColor(Theme.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                    ForEach(cells.indices, id: \.self) { idx in
                        if let day = cells[idx] {
                            NavigationLink {
                                DayDetailView(date: day)
                            } label: {
                                dayCell(day)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.clear.frame(height: 64)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let scheduled = habits.filter { $0.isScheduled(on: day) }
        let allDone = !scheduled.isEmpty && scheduled.allSatisfy { $0.isCompleted(on: day) }
        let anyDone = scheduled.contains { $0.isCompleted(on: day) }
        let isToday = calendar.isDateInToday(day)
        let inSprint = SprintEngine.contains(day, in: sprints) != nil

        let dayColor: Color = {
            if allDone { return .green }
            if isToday { return Theme.accent }
            if inSprint { return Theme.accent }
            return Theme.primaryText
        }()

        let cellBackground: Color = {
            if allDone { return Color.green.opacity(0.12) }
            if isToday { return Theme.cardNavy }
            if inSprint { return Theme.accent.opacity(0.10) }
            return .clear
        }()

        return VStack(spacing: 6) {
            Text("\(calendar.component(.day, from: day))")
                .font(.system(size: 16, weight: isToday || inSprint || allDone ? .bold : .regular))
                .foregroundColor(dayColor)

            ZStack {
                if allDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                } else if anyDone {
                    Circle().fill(Color.orange).frame(width: 6, height: 6)
                } else if !scheduled.isEmpty {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 6, height: 6)
                }
            }
            .frame(height: 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            if hasJournalEntry(day) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 5, height: 5)
                    .padding(4)
            }
        }
    }
}

struct YearCalendar: View {
    @Binding var referenceDate: Date
    let onSelectMonth: (Date) -> Void
    @Query private var habits: [Habit]
    private let calendar = Calendar.current

    private var months: [Date] {
        let year = calendar.component(.year, from: referenceDate)
        return (1...12).compactMap {
            calendar.date(from: DateComponents(year: year, month: $0, day: 1))
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(months, id: \.self) { month in
                    Button {
                        onSelectMonth(month)
                    } label: {
                        monthTile(month)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private func monthTile(_ month: Date) -> some View {
        let isCurrentMonth = calendar.isDate(month, equalTo: Date(), toGranularity: .month)
        let stats = monthStats(month)
        let progress = stats.scheduled == 0 ? 0.0 : Double(stats.complete) / Double(stats.scheduled)

        return VStack(spacing: 8) {
            Text(month, format: .dateTime.month(.abbreviated))
                .font(.headline)
                .foregroundColor(isCurrentMonth ? Theme.accent : Theme.primaryText)
            Text(stats.scheduled == 0 ? "—" : "\(stats.complete)/\(stats.scheduled)")
                .font(.caption2)
                .foregroundColor(Theme.secondaryText)
            ProgressView(value: progress)
                .tint(progress >= 1 ? .green : Theme.accent)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Theme.cardNavy)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func monthStats(_ month: Date) -> (complete: Int, scheduled: Int) {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return (0, 0)
        }
        let today = calendar.startOfDay(for: Date())
        var complete = 0
        var scheduled = 0
        for offset in 0..<range.count {
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else { continue }
            if day > today { break }
            for habit in habits where habit.isScheduled(on: day) {
                scheduled += 1
                if habit.isCompleted(on: day) {
                    complete += 1
                }
            }
        }
        return (complete, scheduled)
    }
}

@ViewBuilder
private func statusIcon(scheduled: [Habit], allDone: Bool, anyDone: Bool, isFuture: Bool) -> some View {
    if isFuture {
        Image(systemName: "circle.dashed")
            .foregroundColor(Theme.secondaryText)
    } else if scheduled.isEmpty {
        Text("—")
            .foregroundColor(Theme.secondaryText)
    } else if allDone {
        Image(systemName: "checkmark")
            .font(.title2.bold())
            .foregroundColor(.green.opacity(0.7))
    } else if anyDone {
        Image(systemName: "circle.lefthalf.filled")
            .foregroundColor(.orange)
    } else {
        Image(systemName: "circle")
            .foregroundColor(Theme.secondaryText)
    }
}

struct DayDetailView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var journalEntries: [JournalEntry]

    private var scheduled: [Habit] {
        habits.filter { $0.isScheduled(on: date) }
    }

    private var orderedScheduled: [Habit] {
        scheduled.filter { $0.isOrdered }.sorted { $0.order < $1.order }
    }

    private var unorderedScheduled: [Habit] {
        scheduled.filter { !$0.isOrdered }
    }

    private var dayEntry: JournalEntry? {
        journalEntries.first {
            Calendar.current.isDate($0.date, inSameDayAs: date) && !$0.content.isEmpty
        }
    }

    var body: some View {
        ZStack {
            Theme.navy.ignoresSafeArea()

            List {
                if scheduled.isEmpty {
                    Text("No habits scheduled for this day.")
                        .foregroundColor(Theme.secondaryText)
                        .listRowBackground(Theme.cardNavy)
                } else {
                    Section {
                        if orderedScheduled.isEmpty {
                            Text("No ordered habits")
                                .foregroundColor(Theme.secondaryText)
                                .listRowBackground(Theme.cardNavy)
                        } else {
                            ForEach(Array(orderedScheduled.enumerated()), id: \.element.id) { index, habit in
                                rowFor(habit, number: index + 1)
                                    .listRowBackground(Theme.cardNavy)
                            }
                        }
                    } header: {
                        Text("Ordered").foregroundColor(Theme.secondaryText)
                    }

                    Section {
                        if unorderedScheduled.isEmpty {
                            Text("No whenever habits")
                                .foregroundColor(Theme.secondaryText)
                                .listRowBackground(Theme.cardNavy)
                        } else {
                            ForEach(unorderedScheduled) { habit in
                                rowFor(habit, number: nil)
                                    .listRowBackground(Theme.cardNavy)
                            }
                        }
                    } header: {
                        Text("Whenever").foregroundColor(Theme.secondaryText)
                    }
                }

                if let entry = dayEntry {
                    Section {
                        Text(entry.content)
                            .foregroundColor(Theme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowBackground(Theme.cardNavy)
                    } header: {
                        HStack {
                            Image(systemName: "book.fill")
                                .font(.caption)
                                .foregroundColor(Theme.accent)
                            Text("Journal").foregroundColor(Theme.secondaryText)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(date.formatted(.dateTime.weekday().month().day()))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rowFor(_ habit: Habit, number: Int?) -> some View {
        let done = habit.isCompleted(on: date)
        return HStack {
            if let number {
                Text("\(number).")
                    .foregroundColor(Theme.secondaryText)
                    .frame(width: 28, alignment: .leading)
            }
            Button {
                toggle(habit)
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(done ? .green : Theme.secondaryText)
            }
            .buttonStyle(.plain)
            Text(habit.name)
                .foregroundColor(done ? Theme.secondaryText : Theme.primaryText)
                .strikethrough(done)
        }
    }

    private func toggle(_ habit: Habit) {
        let day = Calendar.current.startOfDay(for: date)
        if let existing = habit.completions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            modelContext.delete(existing)
        } else {
            let completion = HabitCompletion(date: day, habit: habit)
            modelContext.insert(completion)
        }
        try? modelContext.save()
    }
}
