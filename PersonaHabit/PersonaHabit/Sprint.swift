import Foundation
import SwiftData

@Model
final class Sprint {
    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()
    var notes: String = ""

    init(name: String, startDate: Date = Date(), endDate: Date = Date(), notes: String = "") {
        let cal = Calendar.current
        self.name = name
        self.startDate = cal.startOfDay(for: startDate)
        self.endDate = cal.startOfDay(for: endDate)
        self.notes = notes
    }
}
