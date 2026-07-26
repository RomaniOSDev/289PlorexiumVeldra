import SwiftUI

struct TemperatureTrendView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var inputText = ""
    @State private var noteText = ""
    @State private var selectedTag: ReadingTag?
    @State private var shakeTrigger: CGFloat = 0
    @State private var errorText: String?
    @State private var selectedReading: TemperatureReading?
    @State private var showLogSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if store.readings.isEmpty {
                    EmptyStateView(
                        symbol: "thermometer.sun",
                        title: "Set Your Alerts!",
                        message: "Log your first temperature reading to start tracking trends throughout the day.",
                        actionTitle: "Log Temperature"
                    ) {
                        showLogSheet = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            BannerImageCard(height: 110)
                            gaugeCard
                            comfortCard
                            todaySnapshotCard
                            todayGraphCard
                            highLowList
                            logButton
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Temperature Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticService.light()
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Palette.primary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .toolbarBackground(Palette.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .sheet(isPresented: $showLogSheet) {
                logSheet
            }
        }
    }

    private var gaugeCard: some View {
        SoftCard {
            VStack(spacing: 12) {
                Text("Current Reading")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    TemperatureGaugeView(
                        temperature: store.latestTemperature ?? 20,
                        date: context.date
                    )
                    .frame(height: 160)
                }

                if let temp = store.latestTemperature {
                    Text(String(format: "%.1f°C", temp))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.primary)
                }

                if let latest = store.readings.first {
                    readingMeta(latest)
                }

                HStack {
                    metricPill("High", store.todayHigh.map { String(format: "%.0f°", $0) } ?? "—")
                    metricPill("Low", store.todayLow.map { String(format: "%.0f°", $0) } ?? "—")
                    metricPill("Logs", "\(store.todayReadings.count)")
                }
            }
        }
    }

    @ViewBuilder
    private var comfortCard: some View {
        if store.comfortZone.enabled, let hint = store.comfortHint {
            SoftCard {
                HStack(spacing: 12) {
                    Image(systemName: store.comfortZone.status(for: store.latestTemperature ?? 0).icon)
                        .foregroundStyle(Palette.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comfort Zone")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Palette.textPrimary)
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(Palette.textSecondary)
                        Text(String(format: "Target %.0f° – %.0f°C", store.comfortZone.minCelsius, store.comfortZone.maxCelsius))
                            .font(.caption2)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder
    private var todaySnapshotCard: some View {
        if let snap = store.todaySnapshot {
            SoftCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's Snapshot")
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)
                    HStack {
                        metricPill("Avg", String(format: "%.1f°", snap.average))
                        metricPill("Logs", "\(snap.readingCount)")
                        metricPill("Alerts", snap.hadAlert ? "\(snap.triggerCount)" : "0")
                    }
                }
            }
        }
    }

    private var todayGraphCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Trend")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)

                let today = store.todayReadings
                if today.isEmpty {
                    Text("No readings logged today yet.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.vertical, 28)
                        .frame(maxWidth: .infinity)
                } else {
                    TemperatureCanvasGraph(readings: today, selected: $selectedReading)
                        .frame(height: 180)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectReading(at: value.location.x, width: UIScreen.main.bounds.width - 64, readings: today)
                                }
                        )

                    if let selected = selectedReading {
                        Text(detailLabel(selected))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                        if !selected.note.isEmpty || selected.readingTag != nil {
                            readingMeta(selected)
                        }
                    }
                }
            }
        }
    }

    private var highLowList: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily High / Low")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)

                LazyVStack(spacing: 10) {
                    ForEach(store.weeklyDaySummaries.reversed()) { day in
                        HStack {
                            Text(dayLabel(day.date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                            Text(String(format: "H %.0f°", day.high))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Palette.primary)
                            Text(String(format: "L %.0f°", day.low))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Palette.accent)
                        }
                        .padding(.vertical, 6)
                    }
                }

                if store.alertConfig.anyEnabled {
                    Divider().background(Palette.textSecondary.opacity(0.25))
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(Palette.primary)
                        Text(alertSummary)
                            .font(.caption)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
    }

    private var logButton: some View {
        AccentButtonImage(title: "Log Temperature") {
            showLogSheet = true
        }
    }

    private var logSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Temperature (°C)")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)
                            TextField("e.g. 22.5", text: $inputText)
                                .keyboardType(.decimalPad)
                                .padding(14)
                                .background(Palette.background.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Palette.textPrimary)
                                .modifier(ShakeEffect(animatableData: shakeTrigger))

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
                        submitLog()
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
                    Button("Cancel") {
                        showLogSheet = false
                        resetLogForm()
                    }
                }
            }
            .screenBackground()
        }
        .presentationDetents([.medium, .large])
    }

    private var alertSummary: String {
        var parts: [String] = []
        if store.alertConfig.highEnabled {
            parts.append(String(format: "High ≥ %.0f°", store.alertConfig.highThreshold))
        }
        if store.alertConfig.lowEnabled {
            parts.append(String(format: "Low ≤ %.0f°", store.alertConfig.lowThreshold))
        }
        return parts.joined(separator: " · ")
    }

    private func readingMeta(_ reading: TemperatureReading) -> some View {
        HStack(spacing: 8) {
            if let tag = reading.readingTag {
                Label(tag.title, systemImage: tag.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
            if !reading.note.isEmpty {
                Text(reading.note)
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricPill(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Palette.background.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func submitLog() {
        let normalized = inputText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= -50, value <= 60 else {
            errorText = "Enter a temperature between -50 and 60."
            HapticService.warning()
            withAnimation(.default) { shakeTrigger += 1 }
            return
        }
        store.logTemperature(value, note: noteText.trimmingCharacters(in: .whitespacesAndNewlines), tag: selectedTag?.rawValue ?? "")
        resetLogForm()
        showLogSheet = false
    }

    private func resetLogForm() {
        inputText = ""
        noteText = ""
        selectedTag = nil
        errorText = nil
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func detailLabel(_ reading: TemperatureReading) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return String(format: "%.1f°C at %@", reading.temperature, formatter.string(from: reading.timestamp))
    }

    private func selectReading(at x: CGFloat, width: CGFloat, readings: [TemperatureReading]) {
        guard !readings.isEmpty, width > 0 else { return }
        let ratio = min(max(x / width, 0), 1)
        let index = Int(round(ratio * CGFloat(readings.count - 1)))
        selectedReading = readings[index]
    }
}

struct TemperatureGaugeView: View {
    let temperature: Double
    let date: Date

    private var clamped: Double {
        min(max(temperature, -20), 40)
    }

    private var angle: Angle {
        let ratio = (clamped + 20) / 60
        return .degrees(-120 + ratio * 240)
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .stroke(Palette.background.opacity(0.55), lineWidth: 14)
                    .frame(width: size * 0.85, height: size * 0.85)

                Circle()
                    .trim(from: 0.08, to: 0.92)
                    .stroke(
                        AngularGradient(
                            colors: [Palette.accent, Palette.primary, Color.red.opacity(0.85)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: size * 0.85, height: size * 0.85)

                Capsule()
                    .fill(Palette.primary)
                    .frame(width: 4, height: size * 0.32)
                    .offset(y: -size * 0.16)
                    .rotationEffect(angle)
                    .animation(.easeInOut(duration: 0.35), value: temperature)

                Circle()
                    .fill(Palette.accent)
                    .frame(width: 14, height: 14)
                    .shadow(color: Palette.primary.opacity(0.5), radius: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityLabel("Temperature gauge \(String(format: "%.1f degrees", temperature))")
    }
}

struct TemperatureCanvasGraph: View {
    let readings: [TemperatureReading]
    @Binding var selected: TemperatureReading?

    var body: some View {
        Canvas { context, size in
            guard readings.count >= 1 else { return }
            let temps = readings.map(\.temperature)
            let minT = (temps.min() ?? 0) - 2
            let maxT = (temps.max() ?? 1) + 2
            let range = max(maxT - minT, 1)

            var path = Path()
            for (index, reading) in readings.enumerated() {
                let x = readings.count == 1
                    ? size.width / 2
                    : CGFloat(index) / CGFloat(readings.count - 1) * size.width
                let y = size.height - CGFloat((reading.temperature - minT) / range) * size.height
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [Palette.accent, Palette.primary]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                lineWidth: 3
            )

            for (index, reading) in readings.enumerated() {
                let x = readings.count == 1
                    ? size.width / 2
                    : CGFloat(index) / CGFloat(readings.count - 1) * size.width
                let y = size.height - CGFloat((reading.temperature - minT) / range) * size.height
                let isSelected = selected?.id == reading.id
                let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(isSelected ? Palette.accent : Palette.primary)
                )
            }
        }
    }
}
