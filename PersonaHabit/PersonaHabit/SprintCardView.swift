import SwiftUI

struct SprintCardView: View {
    let sprint: Sprint
    let progress: SprintProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(sprint.name.uppercased())
                    .font(.caption.bold())
                    .foregroundColor(Theme.secondaryText)
                Spacer()
                statusBadge
            }

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: progress.dayFraction)
                    .tint(Theme.accent)
                HStack(alignment: .firstTextBaseline) {
                    Text("Day \(progress.elapsedDays) / \(progress.totalDays)")
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.primaryText)
                    Spacer()
                    Text(daysLeftText)
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: progress.completionFraction)
                    .tint(.green)
                HStack(alignment: .firstTextBaseline) {
                    Text("\(progress.completedDays) / \(progress.totalDays) complete")
                        .font(.subheadline.bold())
                        .foregroundColor(.green.opacity(0.9))
                    Spacer()
                    Text("\(Int(round(progress.completionFraction * 100)))%")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)
                }
            }

            HStack(spacing: 6) {
                Text(sprint.startDate, format: .dateTime.month(.abbreviated).day())
                Text("–")
                Text(sprint.endDate, format: .dateTime.month(.abbreviated).day())
            }
            .font(.caption2)
            .foregroundColor(Theme.secondaryText)
        }
        .padding(16)
        .background(Theme.cardNavy)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statusBadge: some View {
        Group {
            if progress.isComplete {
                Text("COMPLETE").foregroundColor(.green)
            } else if progress.isFuture {
                Text("UPCOMING").foregroundColor(Theme.secondaryText)
            } else {
                Text("ACTIVE").foregroundColor(Theme.accent)
            }
        }
        .font(.caption.bold())
    }

    private var daysLeftText: String {
        if progress.isComplete { return "ended" }
        if progress.isFuture { return "starts soon" }
        return "\(progress.daysRemaining) day\(progress.daysRemaining == 1 ? "" : "s") left"
    }
}
