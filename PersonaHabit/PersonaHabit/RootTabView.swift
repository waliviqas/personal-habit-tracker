import SwiftUI

struct RootTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.navy)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.secondaryText)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.secondaryText)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.navy)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Home", systemImage: "house") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            HabitsView()
                .tabItem { Label("Habits", systemImage: "list.bullet") }

            SprintsView()
                .tabItem { Label("Sprints", systemImage: "flag.checkered") }

            JournalView()
                .tabItem { Label("Journal", systemImage: "book") }
        }
        .tint(.white)
    }
}
