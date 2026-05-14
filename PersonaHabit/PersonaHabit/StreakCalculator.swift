import Foundation

enum StreakCalculator {
    static func currentStreak(habits: [Habit], referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        guard !habits.isEmpty else { return 0 }

        var streak = 0
        var currentDay = today

        if !allCompleted(habits: habits, on: today) {
            currentDay = calendar.date(byAdding: .day, value: -1, to: today)!
        }

        while true {
            let activeHabits = habits.filter { calendar.startOfDay(for: $0.createdAt) <= currentDay }
            if activeHabits.isEmpty { break }

            if allCompleted(habits: activeHabits, on: currentDay) {
                streak += 1
                currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
            } else {
                break
            }

            if streak > 10000 { break }
        }

        return streak
    }

    static func allCompleted(habits: [Habit], on date: Date) -> Bool {
        habits.allSatisfy { $0.isCompleted(on: date) }
    }
}
