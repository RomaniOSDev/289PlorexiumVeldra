import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                SoftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Progress")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        HStack {
                            metric("Alerts", store.stats.itemsCreated)
                            metric("Triggers", store.stats.sessionsCompleted)
                            metric("Readings", store.stats.readingsLogged)
                            metric("Streak", store.stats.streakDays)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(AchievementKind.allCases, id: \.rawValue) { kind in
                        achievementCard(kind)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
        }
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Palette.primary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func achievementCard(_ kind: AchievementKind) -> some View {
        let unlocked = store.unlockedAchievements.contains(kind.rawValue) || kind.isUnlocked(stats: store.stats)
        let progress = min(kind.progress(stats: store.stats), kind.goal)
        return SoftCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: kind.icon)
                    .font(.title2)
                    .foregroundStyle(unlocked ? Palette.primary : Palette.textSecondary)
                    .shadow(color: unlocked ? Palette.primary.opacity(0.45) : .clear, radius: 8)
                Text(kind.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(kind.detail)
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                ProgressView(value: Double(progress), total: Double(kind.goal))
                    .tint(Palette.accent)
                Text("\(progress)/\(kind.goal)")
                    .font(.caption2)
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(unlocked ? 1 : 0.72)
        }
    }
}
