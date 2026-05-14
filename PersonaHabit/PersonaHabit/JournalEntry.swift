import Foundation
import SwiftData

@Model
final class JournalEntry {
    var date: Date = Date()
    var content: String = ""

    init(date: Date, content: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.content = content
    }
}
