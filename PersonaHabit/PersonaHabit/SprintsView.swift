import SwiftUI
import SwiftData

struct SprintsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sprint.startDate, order: .reverse) private var sprints: [Sprint]
    @Query private var habits: [Habit]

    @State private var showNewSprintSheet = false

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    private var activeSprint: Sprint? {
        sprints.first {
            let s = Calendar.current.startOfDay(for: $0.startDate)
            let e = Calendar.current.startOfDay(for: $0.endDate)
            return s <= today && today <= e
        }
    }

    private var futureSprints: [Sprint] {
        sprints.filter { Calendar.current.startOfDay(for: $0.startDate) > today }
    }

    private var pastSprints: [Sprint] {
        sprints.filter { Calendar.current.startOfDay(for: $0.endDate) < today }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()

                List {
                    if let active = activeSprint {
                        Section {
                            NavigationLink {
                                SprintDetailView(sprint: active)
                            } label: {
                                SprintCardView(sprint: active, progress: SprintEngine.compute(active, habits: habits))
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        } header: {
                            Text("Active").foregroundColor(Theme.secondaryText)
                        }
                    }

                    if !futureSprints.isEmpty {
                        Section {
                            ForEach(futureSprints) { sprint in
                                NavigationLink {
                                    SprintDetailView(sprint: sprint)
                                } label: {
                                    sprintRow(sprint)
                                }
                                .listRowBackground(Theme.cardNavy)
                            }
                        } header: {
                            Text("Upcoming").foregroundColor(Theme.secondaryText)
                        }
                    }

                    if !pastSprints.isEmpty {
                        Section {
                            ForEach(pastSprints) { sprint in
                                NavigationLink {
                                    SprintDetailView(sprint: sprint)
                                } label: {
                                    sprintRow(sprint)
                                }
                                .listRowBackground(Theme.cardNavy)
                            }
                        } header: {
                            Text("Past").foregroundColor(Theme.secondaryText)
                        }
                    }

                    if sprints.isEmpty {
                        Section {
                            Text("No sprints yet. Tap + to start one.")
                                .foregroundColor(Theme.secondaryText)
                                .listRowBackground(Theme.cardNavy)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Sprints")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewSprintSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(activeSprint == nil ? .white : Theme.secondaryText)
                    }
                    .disabled(activeSprint != nil)
                }
            }
            .sheet(isPresented: $showNewSprintSheet) {
                NewSprintSheet(suggestedName: "Sprint \(sprints.count + 1)")
            }
        }
    }

    private func sprintRow(_ sprint: Sprint) -> some View {
        let progress = SprintEngine.compute(sprint, habits: habits)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sprint.name)
                    .foregroundColor(Theme.primaryText)
                Text(dateRange(for: sprint))
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            Spacer()
            Text("\(progress.elapsedDays)/\(progress.totalDays)")
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
        }
    }

    private func dateRange(for sprint: Sprint) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return "\(f.string(from: sprint.startDate)) – \(f.string(from: sprint.endDate))"
    }
}

struct NewSprintSheet: View {
    let suggestedName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 24, to: Date()) ?? Date()

    init(suggestedName: String) {
        self.suggestedName = suggestedName
        _name = State(initialValue: suggestedName)
    }

    private var dayCount: Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: startDate)
        let e = cal.startOfDay(for: endDate)
        return max((cal.dateComponents([.day], from: s, to: e).day ?? 0) + 1, 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()
                Form {
                    Section("Name") {
                        TextField("Sprint name", text: $name)
                            .listRowBackground(Theme.cardNavy)
                    }
                    Section {
                        DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                            .listRowBackground(Theme.cardNavy)
                        DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .listRowBackground(Theme.cardNavy)
                    } header: {
                        Text("Schedule")
                    } footer: {
                        Text("\(dayCount) day\(dayCount == 1 ? "" : "s") total")
                            .foregroundColor(Theme.secondaryText)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let sprint = Sprint(name: trimmed, startDate: startDate, endDate: endDate)
                        modelContext.insert(sprint)
                        try? modelContext.save()
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct SprintDetailView: View {
    @Bindable var sprint: Sprint
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    @State private var showDeleteConfirm = false

    private var dayCount: Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: sprint.startDate)
        let e = cal.startOfDay(for: sprint.endDate)
        return max((cal.dateComponents([.day], from: s, to: e).day ?? 0) + 1, 1)
    }

    private var daysInSprint: [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: sprint.startDate)
        let end = cal.startOfDay(for: sprint.endDate)
        var result: [Date] = []
        var day = start
        while day <= end {
            result.append(day)
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    var body: some View {
        ZStack {
            Theme.navy.ignoresSafeArea()
            Form {
                Section {
                    SprintCardView(sprint: sprint, progress: SprintEngine.compute(sprint, habits: habits))
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Name") {
                    TextField("Sprint name", text: $sprint.name)
                        .listRowBackground(Theme.cardNavy)
                }

                Section {
                    DatePicker("Start date", selection: $sprint.startDate, displayedComponents: .date)
                        .listRowBackground(Theme.cardNavy)
                    DatePicker("End date", selection: $sprint.endDate, in: sprint.startDate..., displayedComponents: .date)
                        .listRowBackground(Theme.cardNavy)
                } header: {
                    Text("Schedule")
                } footer: {
                    Text("\(dayCount) day\(dayCount == 1 ? "" : "s") total")
                        .foregroundColor(Theme.secondaryText)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $sprint.notes, axis: .vertical)
                        .lineLimit(3...8)
                        .listRowBackground(Theme.cardNavy)
                }

                Section {
                    ForEach(Array(daysInSprint.enumerated()), id: \.element) { index, day in
                        NavigationLink {
                            DayDetailView(date: day)
                        } label: {
                            dayRow(day, dayNumber: index + 1)
                        }
                        .listRowBackground(Theme.cardNavy)
                    }
                } header: {
                    Text("Daily habits").foregroundColor(Theme.secondaryText)
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Sprint")
                        }
                    }
                    .listRowBackground(Theme.cardNavy)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Sprint")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: sprint.startDate) { _, newValue in
            sprint.startDate = Calendar.current.startOfDay(for: newValue)
            if sprint.endDate < sprint.startDate {
                sprint.endDate = sprint.startDate
            }
            try? modelContext.save()
        }
        .onChange(of: sprint.endDate) { _, newValue in
            sprint.endDate = Calendar.current.startOfDay(for: newValue)
            try? modelContext.save()
        }
        .onChange(of: sprint.name) { _, _ in try? modelContext.save() }
        .onChange(of: sprint.notes) { _, _ in try? modelContext.save() }
        .alert("Delete this sprint?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(sprint)
                try? modelContext.save()
                dismiss()
            }
        }
    }

    private func dayRow(_ day: Date, dayNumber: Int) -> some View {
        let scheduled = habits.filter { $0.isScheduled(on: day) }
        let done = scheduled.filter { $0.isCompleted(on: day) }.count
        let isToday = Calendar.current.isDateInToday(day)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Day \(dayNumber)")
                        .font(.subheadline.bold())
                        .foregroundColor(isToday ? Theme.accent : Theme.primaryText)
                    Text(day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)
                }
                Text(scheduled.isEmpty ? "no habits scheduled" : "\(done) / \(scheduled.count) done")
                    .font(.caption2)
                    .foregroundColor(Theme.secondaryText)
            }
            Spacer()
            if !scheduled.isEmpty && done == scheduled.count {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}
