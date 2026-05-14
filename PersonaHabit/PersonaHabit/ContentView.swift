import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            RootTabView()

            if showSplash {
                SplashView(onDismiss: { showSplash = false })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, JournalEntry.self], inMemory: true)
}
