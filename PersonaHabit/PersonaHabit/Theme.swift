import SwiftUI

enum Theme {
    static let navy = Color(red: 0.05, green: 0.10, blue: 0.28)
    static let cardNavy = Color(red: 0.10, green: 0.17, blue: 0.38)
    static let accent = Color(red: 0.95, green: 0.80, blue: 0.30)

    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.65)
}

struct ThemedScreen<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        ZStack {
            Theme.navy.ignoresSafeArea()
            content
        }
        .scrollContentBackground(.hidden)
        .toolbarBackground(Theme.navy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func themedList() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.navy)
    }
}

enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    static let weekStartingMonday: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    static func from(date: Date) -> Weekday {
        let raw = Calendar.current.component(.weekday, from: date)
        return Weekday(rawValue: raw) ?? .monday
    }
}
