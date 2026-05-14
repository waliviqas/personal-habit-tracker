import Foundation
import SwiftData

@Model
final class Habit {
    var name: String = ""
    var isOrdered: Bool = true
    var order: Int = 0
    var createdAt: Date = Date()
    var weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(name: String, isOrdered: Bool = true, order: Int = 0, weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]) {
        self.name = name
        self.isOrdered = isOrdered
        self.order = order
        self.createdAt = Date()
        self.weekdays = weekdays
    }

    func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return completions.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    func isScheduled(on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekdays.contains(weekday)
    }
}
