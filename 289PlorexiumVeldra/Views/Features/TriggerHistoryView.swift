import SwiftUI

struct TriggerHistoryView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var filter: TriggerFilter = .all
    @State private var query = ""

    private enum TriggerFilter: String, CaseIterable, Identifiable {
        case all, high, low
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: return "All"
            case .high: return "High"
            case .low: return "Low"
            }
        }
    }

    private var filtered: [AlertTriggerEvent] {
        store.triggerEvents.filter { event in
            let kindOK: Bool = {
                switch filter {
                case .all: return true
                case .high: return event.kind == "high"
                case .low: return event.kind == "low"
                }
            }()
            guard kindOK else { return false }
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
            let q = query.lowercased()
            let stamp = timeLabel(event.timestamp).lowercased()
            let temp = String(format: "%.1f", event.temperature)
            return stamp.contains(q) || temp.contains(q) || event.kind.contains(q)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filter")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)

                        HStack(spacing: 8) {
                            ForEach(TriggerFilter.allCases) { item in
                                Button {
                                    HapticService.light()
                                    filter = item
                                } label: {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(filter == item ? Palette.background : Palette.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(filter == item ? Palette.primary : Palette.background.opacity(0.45))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        TextField("Search by time or temp", text: $query)
                            .padding(12)
                            .background(Palette.background.opacity(0.55))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Palette.textPrimary)
                    }
                }

                if filtered.isEmpty {
                    SoftCard {
                        Text("No triggers match this filter.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ForEach(filtered) { event in
                        SoftCard {
                            HStack(spacing: 12) {
                                Image(systemName: event.kind == "high" ? "sun.max.fill" : "snowflake")
                                    .foregroundStyle(Palette.primary)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.kind == "high" ? "High threshold crossed" : "Low threshold crossed")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Palette.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(String(format: "%.1f° vs %.0f° · %@", event.temperature, event.threshold, timeLabel(event.timestamp)))
                                        .font(.caption)
                                        .foregroundStyle(Palette.textSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteTrigger(event)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Trigger History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.surface, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .screenBackground()
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}
