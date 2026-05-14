import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            HabitsView()
                .tabItem { Label("Habits", systemImage: "list.bullet") }

            TrackerView()
                .tabItem { Label("Tracker", systemImage: "chart.bar") }

            JournalView()
                .tabItem { Label("Journal", systemImage: "book") }
        }
    }
}
