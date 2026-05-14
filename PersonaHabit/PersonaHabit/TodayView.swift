import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var habits: [Habit]

    private var orderedHabits: [Habit] {
        habits.filter { $0.isOrdered }.sorted { $0.order < $1.order }
    }

    private var unorderedHabits: [Habit] {
        habits.filter { !$0.isOrdered }
    }

    private var nextOrdered: Habit? {
        orderedHabits.first { !$0.isCompleted(on: Date()) }
    }

    private var allDone: Bool {
        !habits.isEmpty && habits.allSatisfy { $0.isCompleted(on: Date()) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if habits.isEmpty {
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
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if !unorderedHabits.isEmpty {
                            sectionHeader("Whenever today")
                            VStack(spacing: 0) {
                                ForEach(unorderedHabits) { habit in
                                    habitRow(habit: habit)
                                }
                            }
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No habits yet")
                .font(.title2)
            Text("Add your non-negotiables in the Habits tab.")
                .foregroundColor(.secondary)
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
            Text("See you tomorrow.")
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }

    private func nextUpCard(habit: Habit) -> some View {
        VStack(spacing: 16) {
            Text("Next up")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
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
                    .foregroundColor(Color(red: 0.07, green: 0.13, blue: 0.32))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color(red: 0.07, green: 0.13, blue: 0.32))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
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
                    .foregroundColor(done ? .green : .secondary)
            }
            .buttonStyle(.plain)
            Text(habit.name)
                .strikethrough(done)
                .foregroundColor(done ? .secondary : .primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 48)
        }
    }

    private func complete(_ habit: Habit) {
        if !habit.isCompleted(on: Date()) {
            let completion = HabitCompletion(date: Date(), habit: habit)
            modelContext.insert(completion)
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
    }
}
