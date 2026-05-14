import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var draftContent: String = ""
    @State private var showCalendar: Bool = false
    @FocusState private var editorFocused: Bool

    private var selectedEntry: JournalEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()

                VStack(spacing: 0) {
                    dateBar

                    ScrollView {
                        VStack(spacing: 16) {
                            editorCard
                            allEntriesButton
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        selectedDate = Calendar.current.startOfDay(for: Date())
                    }
                    .foregroundColor(Theme.accent)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { editorFocused = false }
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .onAppear { loadDraft(for: selectedDate) }
            .onChange(of: selectedDate) { oldDate, newDate in
                saveDraft(to: oldDate)
                loadDraft(for: newDate)
            }
            .sheet(isPresented: $showCalendar) {
                JournalCalendarPicker(selectedDate: $selectedDate, isPresented: $showCalendar)
            }
        }
    }

    private var dateBar: some View {
        HStack {
            Button { stepDay(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(Theme.primaryText)
            }
            Spacer()
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .colorScheme(.dark)
            .accentColor(Theme.accent)
            Spacer()
            Button { stepDay(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(Theme.primaryText)
            }
        }
        .padding()
        .background(Theme.navy)
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)
                Spacer()
                if let entry = selectedEntry, !entry.content.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            ZStack(alignment: .topLeading) {
                if draftContent.isEmpty && !editorFocused {
                    Text(placeholderText)
                        .foregroundColor(Theme.secondaryText)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $draftContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(Theme.primaryText)
                    .focused($editorFocused)
                    .frame(minHeight: 220)
                    .onChange(of: draftContent) { _, _ in saveDraft(to: selectedDate) }
            }
        }
        .padding(16)
        .background(Theme.cardNavy)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var placeholderText: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "What's on your mind today?"
        } else if selectedDate < Date() {
            return "Looking back — write a note for this day."
        } else {
            return "A note for the future."
        }
    }

    private var allEntriesButton: some View {
        Button {
            showCalendar = true
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.accent)
                Text("All entries")
                    .foregroundColor(Theme.primaryText)
                Spacer()
                Text("\(entries.count)")
                    .foregroundColor(Theme.secondaryText)
                    .font(.subheadline)
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.secondaryText)
                    .font(.caption)
            }
            .padding(16)
            .background(Theme.cardNavy)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func stepDay(_ delta: Int) {
        guard let next = Calendar.current.date(byAdding: .day, value: delta, to: selectedDate) else { return }
        selectedDate = Calendar.current.startOfDay(for: next)
    }

    private func loadDraft(for date: Date) {
        let entry = entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
        draftContent = entry?.content ?? ""
    }

    private func saveDraft(to date: Date) {
        let trimmed = draftContent
        let existing = entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
        if let existing {
            if trimmed.isEmpty {
                modelContext.delete(existing)
            } else if existing.content != trimmed {
                existing.content = trimmed
            }
        } else if !trimmed.isEmpty {
            let entry = JournalEntry(date: date, content: trimmed)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}

struct JournalCalendarPicker: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool

    @Query private var entries: [JournalEntry]

    @State private var displayDate: Date

    private let calendar = Calendar.current

    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        self._displayDate = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.navy.ignoresSafeArea()

                VStack(spacing: 20) {
                    yearBar
                    monthBar
                    weekdayLabels
                    dayGrid
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
            .navigationTitle("All Entries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Today") {
                        let today = calendar.startOfDay(for: Date())
                        displayDate = today
                    }
                    .foregroundColor(Theme.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(Theme.primaryText)
                }
            }
        }
    }

    private var yearBar: some View {
        HStack {
            Button { stepYear(-1) } label: {
                Image(systemName: "chevron.left.2")
                    .foregroundColor(Theme.primaryText)
            }
            Spacer()
            Text(displayDate, format: .dateTime.year())
                .font(.subheadline.bold())
                .foregroundColor(Theme.secondaryText)
            Spacer()
            Button { stepYear(1) } label: {
                Image(systemName: "chevron.right.2")
                    .foregroundColor(Theme.primaryText)
            }
        }
        .padding(.horizontal, 8)
    }

    private var monthBar: some View {
        HStack {
            Button { stepMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(Theme.primaryText)
            }
            Spacer()
            Text(displayDate, format: .dateTime.month(.wide))
                .font(.title2.bold())
                .foregroundColor(Theme.primaryText)
            Spacer()
            Button { stepMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(Theme.primaryText)
            }
        }
    }

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                Text(["M", "T", "W", "T", "F", "S", "S"][i])
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
            ForEach(cells.indices, id: \.self) { idx in
                if let day = cells[idx] {
                    Button {
                        selectedDate = calendar.startOfDay(for: day)
                        isPresented = false
                    } label: {
                        dayCell(day)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 56)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let hasEntry = entries.contains { calendar.isDate($0.date, inSameDayAs: day) }
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)

        return VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: day))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? Theme.accent : Theme.primaryText)
            Circle()
                .fill(hasEntry ? Theme.accent : Color.clear)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isSelected ? Theme.cardNavy : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var cells: [Date?] {
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (firstWeekday + 5) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
        var dates: [Date?] = Array(repeating: nil, count: leading)
        for i in 0..<daysInMonth {
            dates.append(calendar.date(byAdding: .day, value: i, to: firstOfMonth)!)
        }
        return dates
    }

    private func stepMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: displayDate) {
            displayDate = next
        }
    }

    private func stepYear(_ delta: Int) {
        if let next = calendar.date(byAdding: .year, value: delta, to: displayDate) {
            displayDate = next
        }
    }
}
