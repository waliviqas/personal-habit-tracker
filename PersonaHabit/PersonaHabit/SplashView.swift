import SwiftUI
import SwiftData

struct SplashView: View {
    @Query private var habits: [Habit]
    let onDismiss: () -> Void

    private let userName = "Wali"
    private let navy = Color(red: 0.07, green: 0.13, blue: 0.32)

    var body: some View {
        ZStack {
            navy.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Hi, \(userName)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))

                Spacer()

                VStack(spacing: 8) {
                    Text("\(StreakCalculator.currentStreak(habits: habits))")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(StreakCalculator.currentStreak(habits: habits) == 1 ? "day streak" : "day streak")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                Text("Tap to continue")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onDismiss()
        }
    }
}
