import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var habits: [Habit]
    @State private var referenceDate = Date()

    private let calendar = Calendar.current

    private var weekDays: [Date] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate))!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        referenceDate = calendar.date(byAdding: .weekOfYear, value: -1, to: referenceDate)!
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    Spacer()
                    Text(weekRangeText)
                        .font(.headline)
                    Spacer()
                    Button {
                        referenceDate = calendar.date(byAdding: .weekOfYear, value: 1, to: referenceDate)!
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                }
                .padding()

                List {
                    ForEach(weekDays, id: \.self) { day in
                        NavigationLink {
                            DayDetailView(date: day)
                        } label: {
                            dayRow(day)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Calendar")
        }
    }

    private var weekRangeText: String {
        let start = weekDays.first!
        let end = weekDays.last!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    private func dayRow(_ day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let isFuture = day > Date() && !isToday
        let activeHabits = habits.filter { calendar.startOfDay(for: $0.createdAt) <= day }
        let allDone = !activeHabits.isEmpty && activeHabits.allSatisfy { $0.isCompleted(on: day) }
        let anyDone = activeHabits.contains { $0.isCompleted(on: day) }

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day, format: .dateTime.weekday(.wide))
                    .font(.subheadline)
                    .foregroundColor(isToday ? .accentColor : .primary)
                    .bold(isToday)
                Text(day, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isFuture {
                Image(systemName: "circle.dashed")
                    .foregroundColor(.secondary)
            } else if allDone {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .foregroundColor(.green)
            } else if anyDone {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DayDetailView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    private var activeHabits: [Habit] {
        habits.filter { Calendar.current.startOfDay(for: $0.createdAt) <= date }
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            if activeHabits.isEmpty {
                Text("No habits configured for this day.")
                    .foregroundColor(.secondary)
            } else {
                Section("Ordered") {
                    ForEach(activeHabits.filter { $0.isOrdered }) { habit in
                        rowFor(habit)
                    }
                }
                Section("Whenever") {
                    ForEach(activeHabits.filter { !$0.isOrdered }) { habit in
                        rowFor(habit)
                    }
                }
            }
        }
        .navigationTitle(date.formatted(.dateTime.weekday().month().day()))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rowFor(_ habit: Habit) -> some View {
        let done = habit.isCompleted(on: date)
        return HStack {
            Button {
                toggle(habit)
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(done ? .green : .secondary)
            }
            .buttonStyle(.plain)
            Text(habit.name)
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
    }
}
