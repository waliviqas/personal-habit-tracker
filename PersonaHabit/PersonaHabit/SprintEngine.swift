import Foundation

struct SprintProgress {
    let elapsedDays: Int
    let totalDays: Int
    let completedDays: Int
    let daysRemaining: Int
    let isComplete: Bool
    let isFuture: Bool

    var dayFraction: Double {
        guard totalDays > 0 else { return 0 }
        return min(1.0, Double(elapsedDays) / Double(totalDays))
    }

    var completionFraction: Double {
        guard totalDays > 0 else { return 0 }
        return min(1.0, Double(completedDays) / Double(totalDays))
    }
}

enum SprintEngine {
    static func compute(_ sprint: Sprint, habits: [Habit], referenceDate: Date = Date()) -> SprintProgress {
        let cal = Calendar.current
        let start = cal.startOfDay(for: sprint.startDate)
        let end = cal.startOfDay(for: sprint.endDate)
        let today = cal.startOfDay(for: referenceDate)

        let totalDays = max((cal.dateComponents([.day], from: start, to: end).day ?? 0) + 1, 0)

        let isFuture = today < start
        let isComplete = today > end

        var elapsedDays = 0
        var completedDays = 0
        if !isFuture {
            let endBound = min(today, end)
            elapsedDays = max((cal.dateComponents([.day], from: start, to: endBound).day ?? 0) + 1, 0)

            var day = start
            while day <= endBound {
                let scheduled = habits.filter { $0.isScheduled(on: day) }
                if !scheduled.isEmpty && scheduled.allSatisfy({ $0.isCompleted(on: day) }) {
                    completedDays += 1
                }
                guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }

        let daysRemainingRaw = cal.dateComponents([.day], from: today, to: end).day ?? 0
        let daysRemaining = max(daysRemainingRaw + 1, 0)

        return SprintProgress(
            elapsedDays: elapsedDays,
            totalDays: totalDays,
            completedDays: completedDays,
            daysRemaining: isComplete ? 0 : daysRemaining,
            isComplete: isComplete,
            isFuture: isFuture
        )
    }

    static func contains(_ date: Date, in sprints: [Sprint]) -> Sprint? {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        return sprints.first {
            let s = cal.startOfDay(for: $0.startDate)
            let e = cal.startOfDay(for: $0.endDate)
            return s <= day && day <= e
        }
    }
}
