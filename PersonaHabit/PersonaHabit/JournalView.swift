import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var todayContent: String = ""

    private var todayEntry: JournalEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var pastEntries: [JournalEntry] {
        entries.filter { !Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    TextEditor(text: $todayContent)
                        .frame(minHeight: 150)
                        .onChange(of: todayContent) { _, newValue in
                            saveToday(newValue)
                        }
                }

                Section("Past entries") {
                    if pastEntries.isEmpty {
                        Text("No past entries yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(pastEntries) { entry in
                            NavigationLink {
                                JournalEntryDetail(entry: entry)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.date, format: .dateTime.weekday().month().day())
                                        .font(.headline)
                                    Text(entry.content.isEmpty ? "(empty)" : String(entry.content.prefix(80)))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .onAppear {
                todayContent = todayEntry?.content ?? ""
            }
        }
    }

    private func saveToday(_ text: String) {
        if let existing = todayEntry {
            existing.content = text
        } else if !text.isEmpty {
            let entry = JournalEntry(date: Date(), content: text)
            modelContext.insert(entry)
        }
    }
}

struct JournalEntryDetail: View {
    @Bindable var entry: JournalEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .font(.headline)
                TextEditor(text: $entry.content)
                    .frame(minHeight: 300)
            }
            .padding()
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
    }
}
