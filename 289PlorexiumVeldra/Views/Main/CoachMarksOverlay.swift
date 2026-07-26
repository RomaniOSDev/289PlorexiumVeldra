import SwiftUI

struct CoachMarksOverlay: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var selectedTab: Int
    @State private var step = 0

    private let steps: [(tab: Int, title: String, body: String, icon: String)] = [
        (0, "Trends", "Log temperatures and watch today's curve build live.", "thermometer.medium"),
        (1, "Alerts", "Set high/low thresholds or tap a ready-made profile.", "bell.fill"),
        (2, "Insights", "Compare weeks, open daily snapshots, and dig into history.", "chart.xyaxis.line"),
        (3, "Awards", "Unlock achievements as you build streaks and catch alerts.", "trophy.fill"),
        (4, "Settings", "Tune sound, haptics, reminders, comfort zone, and themes.", "gearshape.fill")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .allowsHitTesting(true)

            VStack(spacing: 18) {
                Spacer()

                SoftCard {
                    VStack(spacing: 14) {
                        Image(systemName: steps[step].icon)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Palette.primary)

                        Text("Quick Tour")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.textSecondary)

                        Text(steps[step].title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Palette.textPrimary)

                        Text(steps[step].body)
                            .font(.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 6) {
                            ForEach(steps.indices, id: \.self) { index in
                                Capsule()
                                    .fill(index == step ? Palette.primary : Palette.textSecondary.opacity(0.35))
                                    .frame(width: index == step ? 18 : 7, height: 7)
                            }
                        }
                        .padding(.top, 4)

                        HStack(spacing: 12) {
                            Button("Skip") {
                                store.completeCoachTour()
                            }
                            .foregroundStyle(Palette.textSecondary)
                            .frame(minHeight: 44)

                            Button {
                                HapticService.light()
                                if step < steps.count - 1 {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        step += 1
                                        selectedTab = steps[step].tab
                                    }
                                } else {
                                    store.completeCoachTour()
                                }
                            } label: {
                                Text(step < steps.count - 1 ? "Next" : "Done")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 110)
            }
        }
        .onAppear {
            selectedTab = steps[0].tab
        }
        .transition(.opacity)
        .zIndex(40)
    }
}
