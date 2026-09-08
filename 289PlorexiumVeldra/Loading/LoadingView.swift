import SwiftUI

struct LoadingView: View {
    var body: some View {
        GeometryReader { geo in
            let shortest = min(geo.size.width, geo.size.height)
            let emblem = min(176, max(128, shortest * 0.42))

            ZStack {
                paletteBackground
                ambientGlow(in: geo.size)

                VStack(spacing: 26) {
                    Spacer(minLength: 0)
                    LoadingEmblem(size: emblem)
                    titleBlock
                    LoadingPulseDots()
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    private var paletteBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackground, Color.appSurface, Color.appBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image("img_background")
                .resizable()
                .scaledToFill()
                .opacity(0.18)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .clipped()
    }

    private func ambientGlow(in size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let drift = CGFloat(sin(t * 0.55) * 10)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPrimary.opacity(0.22), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: size.width * 0.38
                        )
                    )
                    .frame(width: size.width * 0.78, height: size.width * 0.78)
                    .offset(x: size.width * 0.28, y: -size.height * 0.28 + drift)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appAccent.opacity(0.16), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: size.width * 0.32
                        )
                    )
                    .frame(width: size.width * 0.68, height: size.width * 0.68)
                    .offset(x: -size.width * 0.32, y: size.height * 0.26 - drift)
            }
            .allowsHitTesting(false)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("Plorexium Veldra")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text("Warming up your instruments")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct LoadingEmblem: View {
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let spin = t.truncatingRemainder(dividingBy: 8) / 8 * 360
            let reverse = -t.truncatingRemainder(dividingBy: 11) / 11 * 360
            let breath = 0.92 + 0.08 * sin(t * 1.6)
            let mercury = 0.28 + 0.42 * (0.5 + 0.5 * sin(t * 1.15))

            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.18))
                    .frame(width: size * 1.18, height: size * 1.18)
                    .scaleEffect(breath)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.appPrimary,
                                Color.appAccent.opacity(0.15),
                                Color.appAccent,
                                Color.appPrimary.opacity(0.2),
                                Color.appPrimary
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(spin))

                Circle()
                    .stroke(
                        Color.appAccent.opacity(0.28),
                        style: StrokeStyle(lineWidth: 1.2, dash: [3, 7])
                    )
                    .frame(width: size * 0.78, height: size * 0.78)
                    .rotationEffect(.degrees(reverse))

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appSurface, Color.appBackground],
                            center: .center,
                            startRadius: 4,
                            endRadius: size * 0.34
                        )
                    )
                    .frame(width: size * 0.62, height: size * 0.62)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.appAccent.opacity(0.55), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                Image(systemName: "thermometer.medium")
                    .font(.system(size: size * 0.26, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.appPrimary.opacity(0.45), radius: 10)
                    .scaleEffect(0.96 + 0.04 * mercury)
                orbitingSparks(t: t, radius: size * 0.5)
            }
            .frame(width: size * 1.2, height: size * 1.2)
            .shadow(color: Color.appPrimary.opacity(0.28), radius: 18, y: 8)
        }
    }

    private func orbitingSparks(t: TimeInterval, radius: CGFloat) -> some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                let angle = (t * 0.85 + Double(index) * 1.256) * .pi
                Circle()
                    .fill(index.isMultiple(of: 2) ? Color.appPrimary : Color.appAccent)
                    .frame(width: index == 0 ? 7 : 5, height: index == 0 ? 7 : 5)
                    .opacity(0.55 + 0.35 * sin(t * 2.2 + Double(index)))
                    .offset(
                        x: CGFloat(cos(angle)) * radius,
                        y: CGFloat(sin(angle)) * radius
                    )
            }
        }
    }
}

private struct LoadingPulseDots: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale(t: t, index: index))
                        .opacity(0.45 + 0.55 * Double(dotScale(t: t, index: index) - 0.7) / 0.3)
                }
            }
        }
    }

    private func dotScale(t: TimeInterval, index: Int) -> CGFloat {
        let period: Double = 0.72
        let offset = Double(index) * 0.18
        let x = (t + offset).truncatingRemainder(dividingBy: period) / period
        return CGFloat(0.7 + 0.3 * max(0, sin(x * .pi)))
    }
}

#Preview {
    LoadingView()
}
