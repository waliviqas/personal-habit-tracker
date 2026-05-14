import SwiftUI
import SwiftData

struct TrackerView: View {
    @Query(sort: \Habit.order) private var habits: [Habit]

    var body: some View {
        NavigationStack {
            List {
                if habits.isEmpty {
                    Text("Add habits in the Habits tab to see progress here.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(habits) { habit in
                        habitRow(habit)
                    }
                }
            }
            .navigationTitle("Tracker")
        }
    }

    private func habitRow(_ habit: Habit) -> some View {
        let total = habit.completions.count
        let last7 = last7DaysCompleted(habit)
        let streak = currentStreakForHabit(habit)

        return VStack(alignment: .leading, spacing: 12) {
            Text(habit.name)
                .font(.headline)

            HStack(spacing: 24) {
                stat(label: "Total", value: "\(total)")
                stat(label: "This week", value: "\(last7)/7")
                stat(label: "Streak", value: "\(streak)")
            }

            HStack(spacing: 4) {
                ForEach(last7Days, id: \.self) { day in
                    let done = habit.isCompleted(on: day)
                    let isToday = Calendar.current.isDateInToday(day)
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(done ? Color.green : Color.secondary.opacity(0.2))
                            .frame(height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Text(day, format: .dateTime.weekday(.narrow))
                            .font(.caption2)
                            .foregroundColor(isToday ? .accentColor : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3).bold()
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    private var last7Days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { cal.date(byAdding: .day, value: -$0, to: today)! }
    }

    private func last7DaysCompleted(_ habit: Habit) -> Int {
        last7Days.filter { habit.isCompleted(on: $0) }.count
    }

    private func currentStreakForHabit(_ habit: Habit) -> Int {
        let cal = Calendar.current
        var streak = 0
        var day = cal.startOfDay(for: Date())
        if !habit.isCompleted(on: day) {
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        while habit.isCompleted(on: day) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
            if streak > 10000 { break }
        }
        return streak
    }
}
