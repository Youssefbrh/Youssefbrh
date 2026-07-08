import SwiftUI

/// Procedurally drawn blob-cat — no image assets, everything is vectors, so
/// it stays crisp at any size.
struct PetView: View {
    @EnvironmentObject var pet: PetEngine
    var size: CGFloat
    var interactive: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            PetBody(mood: pet.mood, time: t, size: size)
        }
        .frame(width: size * 1.6, height: size * 1.4)
        .overlay(alignment: .top) {
            HeartsBurstView(trigger: pet.heartsBurst, size: size)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { pet.pet() }
        }
        .help("\(pet.name) — click to pet")
    }
}

private struct PetBody: View {
    let mood: PetEngine.Mood
    let time: TimeInterval
    let size: CGFloat

    private var bob: CGFloat {
        switch mood {
        case .dancing: return CGFloat(sin(time * 7)) * size * 0.10
        case .walking: return CGFloat(abs(sin(time * 5))) * size * -0.06
        case .sleeping: return CGFloat(sin(time * 1.2)) * size * 0.02
        case .startled: return -size * 0.22
        default: return CGFloat(sin(time * 2)) * size * 0.04
        }
    }

    private var tilt: Angle {
        switch mood {
        case .dancing: return .degrees(sin(time * 7 + 1) * 10)
        case .happy: return .degrees(sin(time * 10) * 6)
        default: return .degrees(0)
        }
    }

    private var eyesClosed: Bool {
        if mood == .sleeping { return true }
        // Occasional blink: ~150 ms every few seconds.
        let cycle = time.truncatingRemainder(dividingBy: 3.7)
        return cycle > 3.55
    }

    private var bodyGradient: LinearGradient {
        let colors: [Color] = mood == .happy
            ? [Color(red: 1.0, green: 0.6, blue: 0.75), Color(red: 0.9, green: 0.4, blue: 0.6)]
            : [Color(red: 0.55, green: 0.6, blue: 0.95), Color(red: 0.35, green: 0.38, blue: 0.75)]
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        ZStack {
            // Ears
            HStack(spacing: size * 0.5) {
                ear
                ear
            }
            .offset(y: -size * 0.42)

            // Body blob
            RoundedRectangle(cornerRadius: size * 0.45, style: .continuous)
                .fill(bodyGradient)
                .frame(width: size * 1.15, height: size * 0.95)

            // Face
            VStack(spacing: size * 0.10) {
                HStack(spacing: size * 0.28) {
                    eye
                    eye
                }
                mouth
            }
            .offset(y: -size * 0.02)

            if mood == .sleeping {
                Text("z")
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .offset(
                        x: size * 0.66,
                        y: -size * 0.5 + CGFloat(sin(time * 1.5)) * 3
                    )
            }
            if mood == .startled {
                Text("!")
                    .font(.system(size: size * 0.4, weight: .heavy, design: .rounded))
                    .foregroundStyle(.yellow)
                    .offset(x: size * 0.62, y: -size * 0.55)
            }
        }
        .rotationEffect(tilt)
        .offset(y: bob)
    }

    private var ear: some View {
        Triangle()
            .fill(bodyGradient)
            .frame(width: size * 0.3, height: size * 0.3)
    }

    private var eye: some View {
        Group {
            if eyesClosed {
                Capsule()
                    .fill(.black.opacity(0.8))
                    .frame(width: size * 0.16, height: size * 0.045)
            } else if mood == .happy {
                Text("♥")
                    .font(.system(size: size * 0.2))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .fill(.black.opacity(0.85))
                    .frame(width: size * 0.15, height: size * 0.15)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: size * 0.05)
                            .offset(x: -size * 0.03, y: -size * 0.03)
                    )
            }
        }
        .frame(height: size * 0.16)
    }

    private var mouth: some View {
        Group {
            if mood == .startled {
                Circle()
                    .fill(.black.opacity(0.7))
                    .frame(width: size * 0.12, height: size * 0.12)
            } else {
                MouthCurve(smiling: mood == .happy || mood == .dancing)
                    .stroke(.black.opacity(0.7), style: StrokeStyle(lineWidth: max(1, size * 0.035), lineCap: .round))
                    .frame(width: size * 0.28, height: size * 0.1)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct MouthCurve: Shape {
    var smiling: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: smiling ? rect.maxY + rect.height : rect.midY)
        )
        return p
    }
}

/// Floating hearts when the pet gets petted.
struct HeartsBurstView: View {
    let trigger: Int
    let size: CGFloat

    @State private var animating = false
    @State private var lastTrigger = 0

    var body: some View {
        ZStack {
            if animating {
                ForEach(0..<5, id: \.self) { i in
                    Text("♥")
                        .font(.system(size: size * 0.22))
                        .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.55))
                        .offset(
                            x: CGFloat(i - 2) * size * 0.22,
                            y: -size * (0.7 + CGFloat(i % 3) * 0.18)
                        )
                        .opacity(0.9)
                        .transition(.asymmetric(
                            insertion: .offset(y: size * 0.4).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue != lastTrigger else { return }
            lastTrigger = newValue
            withAnimation(.easeOut(duration: 0.5)) { animating = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeIn(duration: 0.4)) { animating = false }
            }
        }
        .allowsHitTesting(false)
    }
}

/// The Pet tab: a bigger playground with mood + rename.
struct PetTabView: View {
    @EnvironmentObject var pet: PetEngine
    @AppStorage(Prefs.Key.petName.rawValue) private var petName = "Nova"
    @AppStorage(Prefs.Key.petPeeks.rawValue) private var petPeeks = true

    var body: some View {
        HStack(spacing: 28) {
            PetView(size: 88, interactive: true)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text(petName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("is \(pet.mood.caption)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }

                Button {
                    pet.pet()
                } label: {
                    Label("Pet \(petName)", systemImage: "hand.wave.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.pink.opacity(0.3)))
                        .foregroundStyle(Theme.textPrimary)
                }
                .buttonStyle(.plain)

                Toggle("Peek from the notch while closed", isOn: $petPeeks)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)

                Text("Plays music? \(petName) dances. Drop a file? Jump scare. Click to pet.")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
