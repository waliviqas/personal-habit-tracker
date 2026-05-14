import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var allHabits: [Habit]
    @Query(sort: \Sprint.startDate, order: .reverse) private var sprints: [Sprint]

    private var activeSprint: Sprint? {
        let today = Calendar.current.startOfDay(for: Date())
        return sprints.first {
            let s = Calendar.current.startOfDay(for: $0.startDate)
            let e = Calendar.current.startOfDay(for: $0.endDate)
            return s <= today && today <= e
        }
    }

    private var sprintProgress: SprintProgress? {
        guard let active = activeSprint else { return nil }
        return SprintEngine.compute(active, habits: allHabits)
    }

    private var todayHabits: [Habit] {
        allHabits.filter { $0.isScheduled(on: Date()) }
    }

    private var orderedHabits: [Habit] {
        todayHabits.filter { $0.isOrdered }.sorted { $0.order < $1.order }
    }

    private var unorderedHabits: [Habit] {
        todayHabits.filter { !$0.isOrdered }
    }

    private var nextOrdered: Habit? {
        orderedHabits.first { !$0.isCompleted(on: Date()) }
    }

    private var allDone: Bool {
        !todayHabits.isEmpty && todayHabits.allSatisfy { $0.isCompleted(on: Date()) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if let sprint = activeSprint, let progress = sprintProgress {
                            SprintCardView(sprint: sprint, progress: progress)
                        }

                        if todayHabits.isEmpty {
                            emptyState
                        } else if allDone {
                            celebrationState
                        } else {
                            if let next = nextOrdered {
                                nextUpCard(habit: next)
                            }

                            if !orderedHabits.isEmpty {
                                sectionHeader("Ordered")
                                VStack(spacing: 0) {
                                    ForEach(orderedHabits) { habit in
                                        habitRow(habit: habit)
                                    }
                                }
                                .background(Theme.cardNavy)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            if !unorderedHabits.isEmpty {
                                sectionHeader("Whenever today")
                                VStack(spacing: 0) {
                                    ForEach(unorderedHabits) { habit in
                                        habitRow(habit: habit)
                                    }
                                }
                                .background(Theme.cardNavy)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Home")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf")
                .font(.system(size: 50))
                .foregroundColor(Theme.secondaryText)
            Text("Nothing scheduled today")
                .font(.title2)
                .foregroundColor(Theme.primaryText)
            Text("Add habits in the Habits tab and assign them to today.")
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private var celebrationState: some View {
        VStack(spacing: 16) {
            Text("✓")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.green)
            Text("All done for today")
                .font(.title2)
                .bold()
                .foregroundColor(Theme.primaryText)
            Text("See you tomorrow.")
                .foregroundColor(Theme.secondaryText)
        }
        .padding(.top, 60)
    }

    private func nextUpCard(habit: Habit) -> some View {
        VStack(spacing: 16) {
            Text("Next up")
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
                .textCase(.uppercase)
            Text(habit.name)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Button {
                complete(habit)
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(Theme.navy)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Theme.cardNavy)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(Theme.secondaryText)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private func habitRow(habit: Habit) -> some View {
        let done = habit.isCompleted(on: Date())
        return HStack {
            Button {
                toggle(habit)
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(done ? .green : Theme.secondaryText)
            }
            .buttonStyle(.plain)
            Text(habit.name)
                .strikethrough(done)
                .foregroundColor(done ? Theme.secondaryText : Theme.primaryText)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 48)
        }
    }

    private func complete(_ habit: Habit) {
        if !habit.isCompleted(on: Date()) {
            let completion = HabitCompletion(date: Date(), habit: habit)
            modelContext.insert(completion)
            try? modelContext.save()
        }
    }

    private func toggle(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = habit.completions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            modelContext.delete(existing)
        } else {
            let completion = HabitCompletion(date: Date(), habit: habit)
            modelContext.insert(completion)
        }
        try? modelContext.save()
    }
}
