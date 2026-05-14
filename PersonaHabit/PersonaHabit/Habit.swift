import Foundation
import SwiftData

@Model
final class Habit {
    var name: String = ""
    var isOrdered: Bool = true
    var order: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(name: String, isOrdered: Bool = true, order: Int = 0) {
        self.name = name
        self.isOrdered = isOrdered
        self.order = order
        self.createdAt = Date()
    }

    func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return completions.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }
}
