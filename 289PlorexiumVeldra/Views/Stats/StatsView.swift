import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var weeklyDays: [DayTemperature] { store.weeklyDaySummaries }

    private var readingsPerDay: [(day: Date, count: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).compactMap { offset -> (Date, Int)? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = store.readings.filter { cal.isDate($0.timestamp, inSameDayAs: day) }.count
            return (day, count)
        }.reversed()
    }

    private var triggersPerDay: [(day: Date, high: Int, low: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).compactMap { offset -> (Date, Int, Int)? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let events = store.triggerEvents.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
            let high = events.filter { $0.kind == "high" }.count
            let low = events.filter { $0.kind == "low" }.count
            return (day, high, low)
        }.reversed()
    }

    private var recentReadings: [TemperatureReading] {
        Array(store.readings.prefix(24).reversed())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            statBlock("Alerts Created", store.stats.itemsCreated)
                            statBlock("Alert Triggers", store.stats.sessionsCompleted)
                            statBlock("Readings Logged", store.stats.readingsLogged)
                            statBlock("Current Streak", store.stats.streakDays)
                            statBlock("High Triggers", store.stats.highTriggers)
                            statBlock("Low Triggers", store.stats.lowTriggers)
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week vs Last Week")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        let cmp = store.weekComparison
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            compareBlock("Avg Temp", cmp.thisAvg.map { String(format: "%.1f°", $0) } ?? "—",
                                         cmp.avgDelta.map { String(format: "%@%.1f°", $0 >= 0 ? "+" : "", $0) } ?? "n/a")
                            compareBlock("Spread", cmp.thisSpread.map { String(format: "%.1f°", $0) } ?? "—",
                                         (cmp.thisSpread != nil && cmp.lastSpread != nil)
                                         ? String(format: "%@%.1f°", (cmp.thisSpread! - cmp.lastSpread!) >= 0 ? "+" : "", cmp.thisSpread! - cmp.lastSpread!)
                                         : "n/a")
                            compareBlock("Readings", "\(cmp.thisReadings)",
                                         String(format: "%@%d", cmp.thisReadings - cmp.lastReadings >= 0 ? "+" : "", cmp.thisReadings - cmp.lastReadings))
                            compareBlock("Triggers", "\(cmp.thisTriggers)",
                                         String(format: "%@%d", cmp.thisTriggers - cmp.lastTriggers >= 0 ? "+" : "", cmp.thisTriggers - cmp.lastTriggers))
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly High / Low")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        if weeklyDays.isEmpty {
                            emptyChartLabel("Log temperatures to see weekly ranges.")
                        } else {
                            Chart {
                                ForEach(weeklyDays) { day in
                                    LineMark(
                                        x: .value("Day", day.date, unit: .day),
                                        y: .value("High", day.high),
                                        series: .value("Series", "High")
                                    )
                                    .foregroundStyle(Palette.primary)
                                    .interpolationMethod(.catmullRom)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                    .symbolSize(40)

                                    LineMark(
                                        x: .value("Day", day.date, unit: .day),
                                        y: .value("Low", day.low),
                                        series: .value("Series", "Low")
                                    )
                                    .foregroundStyle(Palette.accent)
                                    .interpolationMethod(.catmullRom)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                    .symbolSize(40)

                                    AreaMark(
                                        x: .value("Day", day.date, unit: .day),
                                        yStart: .value("Low", day.low),
                                        yEnd: .value("High", day.high)
                                    )
                                    .foregroundStyle(Palette.primary.opacity(0.12))
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                                        .foregroundStyle(Palette.textSecondary.opacity(0.2))
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(shortDay(date))
                                                .font(.caption2)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                                        .foregroundStyle(Palette.textSecondary.opacity(0.2))
                                    AxisValueLabel {
                                        if let temp = value.as(Double.self) {
                                            Text(String(format: "%.0f°", temp))
                                                .font(.caption2)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)

                            HStack(spacing: 16) {
                                legendDot(Palette.primary, "High")
                                legendDot(Palette.accent, "Low")
                            }
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Readings Per Day")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        if readingsPerDay.allSatisfy({ $0.count == 0 }) {
                            emptyChartLabel("No readings this week yet.")
                        } else {
                            Chart {
                                ForEach(Array(readingsPerDay.enumerated()), id: \.offset) { _, item in
                                    BarMark(
                                        x: .value("Day", item.day, unit: .day),
                                        y: .value("Count", item.count)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Palette.primary, Palette.accent],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(shortDay(date))
                                                .font(.caption2)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                                        .foregroundStyle(Palette.textSecondary.opacity(0.2))
                                    AxisValueLabel {
                                        if let count = value.as(Int.self) {
                                            Text("\(count)")
                                                .font(.caption2)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                }
                            }
                            .frame(height: 180)
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alert Triggers")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        if triggersPerDay.allSatisfy({ $0.high == 0 && $0.low == 0 }) {
                            emptyChartLabel("No alerts triggered this week.")
                        } else {
                            Chart {
                                ForEach(Array(triggersPerDay.enumerated()), id: \.offset) { _, item in
                                    BarMark(
                                        x: .value("Day", item.day, unit: .day),
                                        y: .value("Count", item.high)
                                    )
                                    .foregroundStyle(Palette.primary)
                                    .position(by: .value("Kind", "High"))

                                    BarMark(
                                        x: .value("Day", item.day, unit: .day),
                                        y: .value("Count", item.low)
                                    )
                                    .foregroundStyle(Palette.accent)
                                    .position(by: .value("Kind", "Low"))
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(shortDay(date))
                                                .font(.caption2)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                                        .foregroundStyle(Palette.textSecondary.opacity(0.2))
                                    AxisValueLabel {
                                        if let count = value.as(Int.self) {
                                            Text("\(count)")
                                                .font(.caption2)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                }
                            }
                            .frame(height: 180)

                            HStack(spacing: 16) {
                                legendDot(Palette.primary, "High")
                                legendDot(Palette.accent, "Low")
                            }
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Readings")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        if recentReadings.isEmpty {
                            emptyChartLabel("Log a temperature to start the chart.")
                        } else {
                            Chart {
                                ForEach(recentReadings) { reading in
                                    LineMark(
                                        x: .value("Time", reading.timestamp),
                                        y: .value("Temp", reading.temperature)
                                    )
                                    .foregroundStyle(Palette.primary)
                                    .interpolationMethod(.catmullRom)

                                    PointMark(
                                        x: .value("Time", reading.timestamp),
                                        y: .value("Temp", reading.temperature)
                                    )
                                    .foregroundStyle(Palette.accent)
                                    .symbolSize(28)
                                }

                                if store.alertConfig.highEnabled {
                                    RuleMark(y: .value("High", store.alertConfig.highThreshold))
                                        .foregroundStyle(Color.red.opacity(0.55))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                }
                                if store.alertConfig.lowEnabled {
                                    RuleMark(y: .value("Low", store.alertConfig.lowThreshold))
                                        .foregroundStyle(Color.cyan.opacity(0.55))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                                        .foregroundStyle(Palette.textSecondary.opacity(0.2))
                                    AxisValueLabel {
                                        if let temp = value.as(Double.self) {
                                            Text(String(format: "%.0f°", temp))
                                                .font(.caption2)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(shortTime(date))
                                                .font(.caption2)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Achievements Unlocked")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        Text("\(store.unlockedAchievements.count) of \(AchievementKind.allCases.count)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Palette.primary)

                        let unlocked = store.unlockedAchievements.count
                        let total = AchievementKind.allCases.count
                        let progress = total == 0 ? 0.0 : Double(unlocked) / Double(total)

                        ZStack {
                            Circle()
                                .stroke(Palette.textSecondary.opacity(0.25), lineWidth: 14)
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    AngularGradient(
                                        colors: [Palette.primary, Palette.accent, Palette.primary],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                            Text("\(Int((progress * 100).rounded()))%")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Palette.textPrimary)
                        }
                        .frame(width: 140, height: 140)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.surface, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .screenBackground()
    }

    private func statBlock(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Palette.background.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func compareBlock(_ title: String, _ value: String, _ delta: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Palette.textPrimary)
            Text(delta)
                .font(.caption2)
                .foregroundStyle(Palette.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Palette.background.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func emptyChartLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Palette.textSecondary)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
    }

    private func legendDot(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
        }
    }

    private func shortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
