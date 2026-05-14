import Foundation
import SwiftData

@Model
final class HabitCompletion {
    var date: Date = Date()
    var habit: Habit?

    init(date: Date, habit: Habit) {
        self.date = Calendar.current.startOfDay(for: date)
        self.habit = habit
    }
}
