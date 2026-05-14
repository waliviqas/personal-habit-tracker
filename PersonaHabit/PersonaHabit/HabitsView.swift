import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HabitsView: View {
    @Query private var habits: [Habit]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()

                List {
                    ForEach(Weekday.weekStartingMonday) { day in
                        NavigationLink {
                            DayHabitsView(weekday: day)
                        } label: {
                            HStack {
                                Text(day.name)
                                    .foregroundColor(Theme.primaryText)
                                Spacer()
                                Text("\(habits.filter { $0.weekdays.contains(day.rawValue) }.count)")
                                    .foregroundColor(Theme.secondaryText)
                            }
                        }
                        .listRowBackground(Theme.cardNavy)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Habits")
        }
    }
}

private enum FocusField: Hashable {
    case ordered, whenever
}

struct DayHabitsView: View {
    let weekday: Weekday
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var allHabits: [Habit]

    @State private var addingOrdered = false
    @State private var addingWhenever = false
    @State private var newOrderedName = ""
    @State private var newWheneverName = ""
    @FocusState private var focusedField: FocusField?

    private var dayHabits: [Habit] {
        allHabits.filter { $0.weekdays.contains(weekday.rawValue) }
    }

    private var orderedHabits: [Habit] {
        dayHabits.filter { $0.isOrdered }.sorted { $0.order < $1.order }
    }

    private var unorderedHabits: [Habit] {
        dayHabits.filter { !$0.isOrdered }.sorted { $0.order < $1.order }
    }

    var body: some View {
        ZStack {
            Theme.navy.ignoresSafeArea()

            List {
                orderedSection
                wheneverSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(weekday.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var orderedSection: some View {
        Section {
            if orderedHabits.isEmpty && !addingOrdered {
                Text("Tap + to add an ordered habit")
                    .foregroundColor(Theme.secondaryText)
                    .listRowBackground(Theme.cardNavy)
            } else {
                ForEach(Array(orderedHabits.enumerated()), id: \.element.id) { index, habit in
                    HStack {
                        Text("\(index + 1).")
                            .foregroundColor(Theme.secondaryText)
                            .frame(width: 28, alignment: .leading)
                        Text(habit.name)
                            .foregroundColor(Theme.primaryText)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Theme.secondaryText)
                            .font(.subheadline)
                    }
                    .contentShape(Rectangle())
                    .listRowBackground(Theme.cardNavy)
                    .draggable("ordered:\(index)") {
                        HStack {
                            Text("\(index + 1).")
                            Text(habit.name)
                        }
                        .padding(8)
                        .background(Theme.cardNavy)
                        .foregroundColor(Theme.primaryText)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        handleDrop(items: items, targetIndex: index, isOrdered: true)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            removeFromDay(habit)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }

            if addingOrdered {
                HStack {
                    Text("\(orderedHabits.count + 1).")
                        .foregroundColor(Theme.secondaryText)
                        .frame(width: 28, alignment: .leading)
                    TextField(
                        "",
                        text: $newOrderedName,
                        prompt: Text("New habit").foregroundColor(Theme.secondaryText)
                    )
                    .textFieldStyle(.plain)
                    .foregroundColor(Theme.primaryText)
                    .focused($focusedField, equals: .ordered)
                    .submitLabel(.done)
                    .onSubmit { commitOrdered() }
                    Button {
                        cancelOrdered()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Theme.cardNavy)
            }
        } header: {
            sectionHeader(title: "Ordered") {
                addingOrdered = true
                focusedField = .ordered
            }
        }
    }

    private var wheneverSection: some View {
        Section {
            if unorderedHabits.isEmpty && !addingWhenever {
                Text("Tap + to add a whenever habit")
                    .foregroundColor(Theme.secondaryText)
                    .listRowBackground(Theme.cardNavy)
            } else {
                ForEach(Array(unorderedHabits.enumerated()), id: \.element.id) { index, habit in
                    HStack {
                        Text(habit.name)
                            .foregroundColor(Theme.primaryText)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Theme.secondaryText)
                            .font(.subheadline)
                    }
                    .contentShape(Rectangle())
                    .listRowBackground(Theme.cardNavy)
                    .draggable("whenever:\(index)") {
                        Text(habit.name)
                            .padding(8)
                            .background(Theme.cardNavy)
                            .foregroundColor(Theme.primaryText)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        handleDrop(items: items, targetIndex: index, isOrdered: false)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            removeFromDay(habit)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }

            if addingWhenever {
                HStack {
                    TextField(
                        "",
                        text: $newWheneverName,
                        prompt: Text("New habit").foregroundColor(Theme.secondaryText)
                    )
                    .textFieldStyle(.plain)
                    .foregroundColor(Theme.primaryText)
                    .focused($focusedField, equals: .whenever)
                    .submitLabel(.done)
                    .onSubmit { commitWhenever() }
                    Button {
                        cancelWhenever()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Theme.cardNavy)
            }
        } header: {
            sectionHeader(title: "Whenever") {
                addingWhenever = true
                focusedField = .whenever
            }
        }
    }

    private func sectionHeader(title: String, onAdd: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .foregroundColor(Theme.secondaryText)
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }

    private func handleDrop(items: [String], targetIndex: Int, isOrdered: Bool) -> Bool {
        guard let item = items.first else { return false }
        let parts = item.split(separator: ":")
        guard parts.count == 2,
              let sourceIndex = Int(parts[1]) else { return false }
        let sourceIsOrdered = parts[0] == "ordered"
        guard sourceIsOrdered == isOrdered else { return false }

        if isOrdered {
            moveOrdered(from: sourceIndex, to: targetIndex)
        } else {
            moveUnordered(from: sourceIndex, to: targetIndex)
        }
        return true
    }

    private func commitOrdered() {
        let trimmed = newOrderedName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let nextOrder = (allHabits.filter { $0.isOrdered }.map(\.order).max() ?? -1) + 1
            let habit = Habit(name: trimmed, isOrdered: true, order: nextOrder, weekdays: [weekday.rawValue])
            modelContext.insert(habit)
        }
        newOrderedName = ""
        focusedField = .ordered
    }

    private func cancelOrdered() {
        newOrderedName = ""
        addingOrdered = false
        focusedField = nil
    }

    private func commitWhenever() {
        let trimmed = newWheneverName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let nextOrder = (allHabits.filter { !$0.isOrdered }.map(\.order).max() ?? -1) + 1
            let habit = Habit(name: trimmed, isOrdered: false, order: nextOrder, weekdays: [weekday.rawValue])
            modelContext.insert(habit)
        }
        newWheneverName = ""
        focusedField = .whenever
    }

    private func cancelWhenever() {
        newWheneverName = ""
        addingWhenever = false
        focusedField = nil
    }

    private func removeFromDay(_ habit: Habit) {
        habit.weekdays.removeAll { $0 == weekday.rawValue }
        if habit.weekdays.isEmpty {
            modelContext.delete(habit)
        }
    }

    private func moveOrdered(from source: Int, to target: Int) {
        guard source != target else { return }
        var list = orderedHabits
        let item = list.remove(at: source)
        let insertIndex = source < target ? target - 1 : target
        let safeIndex = min(max(insertIndex, 0), list.count)
        list.insert(item, at: safeIndex)
        for (index, habit) in list.enumerated() {
            habit.order = index
        }
    }

    private func moveUnordered(from source: Int, to target: Int) {
        guard source != target else { return }
        var list = unorderedHabits
        let item = list.remove(at: source)
        let insertIndex = source < target ? target - 1 : target
        let safeIndex = min(max(insertIndex, 0), list.count)
        list.insert(item, at: safeIndex)
        for (index, habit) in list.enumerated() {
            habit.order = index
        }
    }
}
