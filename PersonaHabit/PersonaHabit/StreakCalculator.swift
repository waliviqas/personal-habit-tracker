import Foundation

enum StreakCalculator {
    static func currentStreak(habits: [Habit], referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        guard !habits.isEmpty else { return 0 }
        guard let earliest = habits.map({ calendar.startOfDay(for: $0.createdAt) }).min() else { return 0 }

        var streak = 0
        var currentDay = today

        let todayScheduled = scheduledHabits(habits, on: today, calendar: calendar)
        if !todayScheduled.isEmpty && !allCompleted(habits: todayScheduled, on: today) {
            guard let prev = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            currentDay = prev
        }

        while currentDay >= earliest {
            let scheduled = scheduledHabits(habits, on: currentDay, calendar: calendar)

            if scheduled.isEmpty {
                guard let prev = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
                currentDay = prev
                continue
            }

            if allCompleted(habits: scheduled, on: currentDay) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
                currentDay = prev
            } else {
                break
            }
        }

        return streak
    }

    private static func scheduledHabits(_ habits: [Habit], on day: Date, calendar: Calendar) -> [Habit] {
        habits.filter { habit in
            calendar.startOfDay(for: habit.createdAt) <= day && habit.isScheduled(on: day)
        }
    }

    static func allCompleted(habits: [Habit], on date: Date) -> Bool {
        habits.allSatisfy { $0.isCompleted(on: date) }
    }
}
