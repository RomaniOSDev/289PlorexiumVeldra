import SwiftUI

struct TemperatureInsightsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAddAlert = false
    @State private var showLog = false
    @State private var selectedDay: DayTemperature?
    @State private var bounceID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if store.readings.isEmpty && store.daySummaries.isEmpty {
                    EmptyStateView(
                        symbol: "thermometer",
                        title: "No data available",
                        message: "Log temperatures or set alerts to unlock weekly insights and daily summaries.",
                        actionTitle: "Log Temperature"
                    ) {
                        showLog = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headerCard
                            weekComparisonCard
                            weeklyChartCard
                            snapshotsCard
                            dayCards
                            actionButtons
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .sheet(isPresented: $showAddAlert) {
                AddAlertQuickSheet(isPresented: $showAddAlert)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showLog) {
                LogTemperatureSheet(isPresented: $showLog)
                    .environmentObject(store)
            }
            .sheet(item: $selectedDay) { day in
                DayDetailSheet(day: day)
                    .environmentObject(store)
            }
        }
    }

    private var headerCard: some View {
        SoftCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Overview")
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)
                    Text(currentDateLabel)
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image("img_card")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var weeklyChartCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Past 7 Days")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)

                let days = store.weeklyDaySummaries
                if days.isEmpty {
                    Text("Not enough history yet.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.vertical, 28)
                        .frame(maxWidth: .infinity)
                } else {
                    WeeklyTemperatureCanvas(days: days)
                        .frame(height: 180)
                }
            }
        }
    }

    private var weekComparisonCard: some View {
        let cmp = store.weekComparison
        return SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week vs Last Week")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)

                HStack(spacing: 10) {
                    comparePill("Avg", cmp.thisAvg, cmp.lastAvg, suffix: "°")
                    comparePill("Spread", cmp.thisSpread, cmp.lastSpread, suffix: "°")
                }
                HStack(spacing: 10) {
                    compareCount("Readings", cmp.thisReadings, cmp.lastReadings)
                    compareCount("Triggers", cmp.thisTriggers, cmp.lastTriggers)
                }
            }
        }
    }

    private var snapshotsCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Snapshots")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)

                let snaps = Array(store.dailySnapshots.prefix(7))
                if snaps.isEmpty {
                    Text("Snapshots appear after you log temperatures.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    ForEach(snaps) { snap in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dayTitle(snap.date))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text(String(format: "%d logs · avg %.1f°", snap.readingCount, snap.average))
                                    .font(.caption)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "H %.0f° L %.0f°", snap.high, snap.low))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Palette.primary)
                                Text(snap.hadAlert ? "Alert fired" : "No alerts")
                                    .font(.caption2)
                                    .foregroundStyle(snap.hadAlert ? Palette.accent : Palette.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func comparePill(_ title: String, _ thisValue: Double?, _ lastValue: Double?, suffix: String) -> some View {
        let delta = (thisValue != nil && lastValue != nil) ? (thisValue! - lastValue!) : nil
        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
            Text(thisValue.map { String(format: "%.1f%@", $0, suffix) } ?? "—")
                .font(.headline)
                .foregroundStyle(Palette.textPrimary)
            Text(delta.map { String(format: "%@%.1f vs last", $0 >= 0 ? "+" : "", $0) } ?? "No prior week")
                .font(.caption2)
                .foregroundStyle(Palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Palette.background.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func compareCount(_ title: String, _ thisValue: Int, _ lastValue: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
            Text("\(thisValue)")
                .font(.headline)
                .foregroundStyle(Palette.textPrimary)
            Text(String(format: "%@%d vs last", thisValue - lastValue >= 0 ? "+" : "", thisValue - lastValue))
                .font(.caption2)
                .foregroundStyle(Palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Palette.background.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var dayCards: some View {
        VStack(spacing: 12) {
            ForEach(store.weeklyDaySummaries.reversed()) { day in
                SoftCard {
                    Button {
                        HapticService.light()
                        selectedDay = day
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dayTitle(day.date))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Palette.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text(alertNote)
                                    .font(.caption)
                                    .foregroundStyle(Palette.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "Max %.0f°", day.high))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Palette.primary)
                                Text(String(format: "Min %.0f°", day.low))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(bounceID == day.id ? 1.04 : 1)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: bounceID)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteDay(day)
                        } label: {
                            Label("Delete Day Logs", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            AccentButtonImage(title: "Add Alert") {
                showAddAlert = true
                if let first = store.weeklyDaySummaries.last {
                    bounceID = first.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        bounceID = nil
                    }
                }
            }
            Button {
                HapticService.light()
                showLog = true
            } label: {
                Text("Log Reading")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var alertNote: String {
        if store.alertConfig.anyEnabled {
            var parts: [String] = []
            if store.alertConfig.highEnabled {
                parts.append(String(format: "High %.0f°", store.alertConfig.highThreshold))
            }
            if store.alertConfig.lowEnabled {
                parts.append(String(format: "Low %.0f°", store.alertConfig.lowThreshold))
            }
            return parts.joined(separator: " · ")
        }
        return "No alerts configured"
    }

    private var currentDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private func dayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func deleteDay(_ day: DayTemperature) {
        let cal = Calendar.current
        let toRemove = store.readings.filter { cal.isDate($0.timestamp, inSameDayAs: day.date) }
        for reading in toRemove {
            store.deleteReading(reading)
        }
        HapticService.warning()
    }
}

struct WeeklyTemperatureCanvas: View {
    let days: [DayTemperature]

    var body: some View {
        Canvas { context, size in
            guard !days.isEmpty else { return }
            let highs = days.map(\.high)
            let lows = days.map(\.low)
            let minT = (lows.min() ?? 0) - 2
            let maxT = (highs.max() ?? 1) + 2
            let range = max(maxT - minT, 1)

            func point(index: Int, value: Double) -> CGPoint {
                let x = days.count == 1
                    ? size.width / 2
                    : CGFloat(index) / CGFloat(days.count - 1) * size.width
                let y = size.height - CGFloat((value - minT) / range) * size.height
                return CGPoint(x: x, y: y)
            }

            var highPath = Path()
            var lowPath = Path()
            for (index, day) in days.enumerated() {
                let hp = point(index: index, value: day.high)
                let lp = point(index: index, value: day.low)
                if index == 0 {
                    highPath.move(to: hp)
                    lowPath.move(to: lp)
                } else {
                    highPath.addLine(to: hp)
                    lowPath.addLine(to: lp)
                }
            }

            context.stroke(highPath, with: .color(Palette.primary), lineWidth: 3)
            context.stroke(lowPath, with: .color(Palette.accent), lineWidth: 3)

            for (index, day) in days.enumerated() {
                let hp = point(index: index, value: day.high)
                let lp = point(index: index, value: day.low)
                context.fill(Path(ellipseIn: CGRect(x: hp.x - 3.5, y: hp.y - 3.5, width: 7, height: 7)), with: .color(Palette.primary))
                context.fill(Path(ellipseIn: CGRect(x: lp.x - 3.5, y: lp.y - 3.5, width: 7, height: 7)), with: .color(Palette.accent))
            }
        }
    }
}

struct DayDetailSheet: View {
    @EnvironmentObject private var store: AppDataStore
    let day: DayTemperature

    private var snapshot: DaySnapshot? {
        store.dailySnapshots.first { Calendar.current.isDate($0.date, inSameDayAs: day.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(format: "High %.1f°C", day.high))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Palette.primary)
                            Text(String(format: "Low %.1f°C", day.low))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Palette.accent)

                            if let snapshot {
                                Text(String(format: "Average %.1f°C · %d readings", snapshot.average, snapshot.readingCount))
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.textSecondary)
                                Text(snapshot.hadAlert
                                      ? "Alerts fired: \(snapshot.triggerCount) (H \(snapshot.highTriggers) / L \(snapshot.lowTriggers))"
                                      : "No alerts fired this day")
                                    .font(.caption)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Readings")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)

                            let cal = Calendar.current
                            let dayReadings = store.readings
                                .filter { cal.isDate($0.timestamp, inSameDayAs: day.date) }
                                .sorted { $0.timestamp < $1.timestamp }

                            if dayReadings.isEmpty {
                                Text("No individual readings stored.")
                                    .foregroundStyle(Palette.textSecondary)
                            } else {
                                ForEach(dayReadings) { reading in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(timeLabel(reading.timestamp))
                                                .foregroundStyle(Palette.textSecondary)
                                            Spacer()
                                            Text(String(format: "%.1f°C", reading.temperature))
                                                .foregroundStyle(Palette.textPrimary)
                                                .fontWeight(.semibold)
                                        }
                                        if let tag = reading.readingTag {
                                            Label(tag.title, systemImage: tag.icon)
                                                .font(.caption)
                                                .foregroundStyle(Palette.accent)
                                        }
                                        if !reading.note.isEmpty {
                                            Text(reading.note)
                                                .font(.caption)
                                                .foregroundStyle(Palette.textSecondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .screenBackground()
        }
        .presentationDetents([.medium, .large])
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct LogTemperatureSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var isPresented: Bool
    @State private var inputText = ""
    @State private var noteText = ""
    @State private var selectedTag: ReadingTag?
    @State private var shake: CGFloat = 0
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Temperature (°C)")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)
                            TextField("e.g. 18.0", text: $inputText)
                                .keyboardType(.decimalPad)
                                .padding(14)
                                .background(Palette.background.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Palette.textPrimary)
                                .modifier(ShakeEffect(animatableData: shake))
                            if let errorText {
                                Text(errorText)
                                    .font(.caption)
                                    .foregroundStyle(Color.red.opacity(0.9))
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Place Tag")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ReadingTag.allCases) { tag in
                                        Button {
                                            HapticService.light()
                                            selectedTag = selectedTag == tag ? nil : tag
                                        } label: {
                                            Label(tag.title, systemImage: tag.icon)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(selectedTag == tag ? Palette.background : Palette.textPrimary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(selectedTag == tag ? Palette.primary : Palette.background.opacity(0.5))
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            Text("Note")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)
                            TextField("Optional note", text: $noteText, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(14)
                                .background(Palette.background.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Palette.textPrimary)
                        }
                    }

                    Button {
                        save()
                    } label: {
                        Text("Save Reading")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(16)
            }
            .navigationTitle("Log Temperature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .screenBackground()
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let normalized = inputText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= -50, value <= 60 else {
            errorText = "Enter a temperature between -50 and 60."
            HapticService.warning()
            withAnimation(.default) { shake += 1 }
            return
        }
        store.logTemperature(
            value,
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            tag: selectedTag?.rawValue ?? ""
        )
        isPresented = false
    }
}

struct AddAlertQuickSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var isPresented: Bool
    @State private var highEnabled = true
    @State private var lowEnabled = true
    @State private var highThreshold: Double = 30
    @State private var lowThreshold: Double = 5

    var body: some View {
        NavigationStack {
            Form {
                Section("High Temperature Alert") {
                    Toggle("Enable", isOn: $highEnabled)
                        .tint(Palette.primary)
                        .listRowBackground(Palette.surface)
                    if highEnabled {
                        Slider(value: $highThreshold, in: -20...50, step: 1)
                            .tint(Palette.primary)
                            .listRowBackground(Palette.surface)
                        Text(String(format: "%.0f°C", highThreshold))
                            .foregroundStyle(Palette.textPrimary)
                            .listRowBackground(Palette.surface)
                    }
                }
                Section("Low Temperature Alert") {
                    Toggle("Enable", isOn: $lowEnabled)
                        .tint(Palette.primary)
                        .listRowBackground(Palette.surface)
                    if lowEnabled {
                        Slider(value: $lowThreshold, in: -40...40, step: 1)
                            .tint(Palette.accent)
                            .listRowBackground(Palette.surface)
                        Text(String(format: "%.0f°C", lowThreshold))
                            .foregroundStyle(Palette.textPrimary)
                            .listRowBackground(Palette.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Add Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard highEnabled || lowEnabled else {
                            HapticService.warning()
                            return
                        }
                        store.saveAlerts(
                            TemperatureAlertConfig(
                                highEnabled: highEnabled,
                                lowEnabled: lowEnabled,
                                highThreshold: highThreshold,
                                lowThreshold: lowThreshold
                            )
                        )
                        isPresented = false
                    }
                }
            }
            .screenBackground()
            .onAppear {
                if store.alertConfig.anyEnabled {
                    highEnabled = store.alertConfig.highEnabled
                    lowEnabled = store.alertConfig.lowEnabled
                } else {
                    highEnabled = true
                    lowEnabled = true
                }
                highThreshold = store.alertConfig.highThreshold
                lowThreshold = store.alertConfig.lowThreshold
            }
        }
    }
}
