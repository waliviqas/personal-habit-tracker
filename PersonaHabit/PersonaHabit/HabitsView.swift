import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var habits: [Habit]
    @State private var showAddSheet = false

    private var orderedHabits: [Habit] {
        habits.filter { $0.isOrdered }.sorted { $0.order < $1.order }
    }

    private var unorderedHabits: [Habit] {
        habits.filter { !$0.isOrdered }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if orderedHabits.isEmpty {
                        Text("No ordered habits yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(orderedHabits) { habit in
                            Text(habit.name)
                        }
                        .onDelete(perform: deleteOrdered)
                        .onMove(perform: moveOrdered)
                    }
                } header: {
                    Text("Ordered (do in sequence)")
                } footer: {
                    Text("These appear in order on the Today tab. Long-press the Edit button to reorder.")
                        .font(.caption)
                }

                Section {
                    if unorderedHabits.isEmpty {
                        Text("No whenever-today habits yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(unorderedHabits) { habit in
                            Text(habit.name)
                        }
                        .onDelete(perform: deleteUnordered)
                    }
                } header: {
                    Text("Whenever today")
                } footer: {
                    Text("Must be done sometime today, no specific order.")
                        .font(.caption)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("Habits")
            .sheet(isPresented: $showAddSheet) {
                AddHabitSheet()
            }
        }
    }

    private func deleteOrdered(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(orderedHabits[index])
        }
    }

    private func deleteUnordered(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(unorderedHabits[index])
        }
    }

    private func moveOrdered(from source: IndexSet, to destination: Int) {
        var list = orderedHabits
        list.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in list.enumerated() {
            habit.order = index
        }
    }
}

struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    @State private var name = ""
    @State private var isOrdered = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Hit the gym", text: $name)
                }
                Section("Type") {
                    Picker("Type", selection: $isOrdered) {
                        Text("Ordered").tag(true)
                        Text("Whenever").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addHabit()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let nextOrder: Int
        if isOrdered {
            nextOrder = (habits.filter { $0.isOrdered }.map(\.order).max() ?? -1) + 1
        } else {
            nextOrder = 0
        }
        let habit = Habit(name: trimmedName, isOrdered: isOrdered, order: nextOrder)
        modelContext.insert(habit)
    }
}
