import SwiftUI
import Combine

// MARK: - Model

enum SimonPad: Int, CaseIterable, Identifiable {
    case green = 0
    case red = 1
    case yellow = 2
    case blue = 3

    var id: Int { rawValue }

    var color: Color {
        switch self {
        case .green: return .green
        case .red: return .red
        case .yellow: return .yellow
        case .blue: return .blue
        }
    }

    var highlightColor: Color {
        switch self {
        case .green: return Color.green.opacity(0.9)
        case .red: return Color.red.opacity(0.9)
        case .yellow: return Color.yellow.opacity(0.95)
        case .blue: return Color.blue.opacity(0.9)
        }
    }

    var systemIcon: String {
        // Optional icon overlay per pad (kept subtle)
        switch self {
        case .green: return "triangle.fill"
        case .red: return "square.fill"
        case .yellow: return "diamond.fill"
        case .blue: return "circle.fill"
        }
    }
}

// MARK: - ViewModel

@MainActor
final class SimonGameViewModel: ObservableObject {
    // Published state
    @Published private(set) var sequence: [SimonPad] = []
    @Published private(set) var playbackIndex: Int = -1
    @Published private(set) var isPlayingBack: Bool = false
    @Published private(set) var acceptingInput: Bool = false
    @Published private(set) var userIndex: Int = 0
    @Published private(set) var score: Int = 0
    @Published private(set) var isGameOver: Bool = false
    @Published var highlightedPad: SimonPad? = nil

    // Timing
    private var timer: AnyCancellable?
    private var noteDuration: TimeInterval = 0.5
    private var gapDuration: TimeInterval = 0.22

    // Difficulty progression
    private var speedupEvery: Int = 4
    private var speedMultiplier: Double = 0.92

    init() {
        newGame()
    }

    func newGame() {
        stopTimer()
        sequence = []
        score = 0
        isGameOver = false
        acceptingInput = false
        isPlayingBack = false
        playbackIndex = -1
        userIndex = 0
        highlightedPad = nil
        appendRandomAndPlay()
    }

    func stop() {
        stopTimer()
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func appendRandomAndPlay() {
        if let random = SimonPad.allCases.randomElement() {
            sequence.append(random)
        }
        userIndex = 0
        playSequence()
    }

    private func playSequence() {
        stopTimer()
        isPlayingBack = true
        acceptingInput = false
        playbackIndex = -1
        highlightedPad = nil

        // Playback loop via Combine timer
        let totalSteps = sequence.count * 2 // on + off steps
        var step = 0

        timer = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                let onFrames = Int(self.noteDuration / 0.01)
                let offFrames = Int(self.gapDuration / 0.01)

                // Determine which "pair" we are in
                let pair = step / (onFrames + offFrames)
                let within = step % (onFrames + offFrames)

                if pair < self.sequence.count {
                    if within == 0 {
                        // Start note
                        self.playbackIndex = pair
                        let pad = self.sequence[pair]
                        self.highlightedPad = pad
                    }

                    if within >= onFrames {
                        // End note (gap)
                        self.highlightedPad = nil
                    }
                }

                step += 1
                if pair >= self.sequence.count {
                    // Finished
                    self.stopTimer()
                    self.isPlayingBack = false
                    self.acceptingInput = true
                    self.playbackIndex = -1
                    self.highlightedPad = nil
                }
            }
    }

    func tap(_ pad: SimonPad) {
        guard acceptingInput, !isPlayingBack, !isGameOver else { return }

        // Flash the pad briefly for tap feedback
        flash(pad)

        let expected = sequence[userIndex]
        if pad == expected {
            userIndex += 1
            if userIndex == sequence.count {
                // Round complete
                score += 1
                acceptingInput = false
                // Adjust difficulty over time
                if score % speedupEvery == 0 {
                    noteDuration *= speedMultiplier
                    gapDuration = max(0.12, gapDuration * speedMultiplier)
                }
                // Small delay before next sequence
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    await self?.appendRandomAndPlay()
                }
            }
        } else {
            // Wrong input
            gameOver()
        }
    }

    private func flash(_ pad: SimonPad) {
        highlightedPad = pad
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            await MainActor.run {
                self?.highlightedPad = nil
            }
        }
    }

    private func gameOver() {
        isGameOver = true
        acceptingInput = false
        isPlayingBack = false
        stopTimer()
        highlightedPad = nil
    }
}

// MARK: - View

public struct SimonGameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SimonGameViewModel()

    public init() {}

    public var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 16) {
                header
                board
                controls
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color("blue1"), Color("blue2")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .onDisappear { vm.stop() }

            // Back button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.96))
                    .frame(width: 44, height: 44, alignment: .center)
                    .background(
                        GlassBackground(cornerRadius: 14)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 6)
                    .transition(.move(edge: .leading))
            }
            .padding(.top, 12)
            .padding(.leading, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Text("Simon")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Text("Score: \(vm.score)")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            Button {
                vm.newGame()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .padding(.leading, 8)
        }
    }

    private var board: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.black.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    simonPad(.green)
                    simonPad(.red)
                }
                HStack(spacing: 12) {
                    simonPad(.yellow)
                    simonPad(.blue)
                }
            }
            .padding(16)

            if vm.isGameOver {
                VStack(spacing: 10) {
                    Text("Game Over")
                        .font(.system(.title, design: .rounded).weight(.bold))
                    Text("Score: \(vm.score)")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.secondary)
                    Button("Play Again") {
                        vm.newGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(radius: 8)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
    }

    private func simonPad(_ pad: SimonPad) -> some View {
        let isLit = vm.highlightedPad == pad
        return Button {
            vm.tap(pad)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                (isLit ? pad.highlightColor : pad.color).opacity(0.95),
                                (isLit ? pad.highlightColor : pad.color).opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isLit ? .white.opacity(0.7) : .white.opacity(0.25), lineWidth: isLit ? 2 : 1)
                    )
                    .shadow(color: .black.opacity(isLit ? 0.35 : 0.22), radius: isLit ? 16 : 10, x: 0, y: isLit ? 10 : 6)

                Image(systemName: pad.systemIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(isLit ? 1.0 : 0.75)
                    .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .animation(.easeInOut(duration: 0.12), value: isLit)
        }
        .buttonStyle(.plain)
        .disabled(!vm.acceptingInput || vm.isGameOver)
        .accessibilityLabel(Text(accessibilityName(for: pad)))
    }

    private func accessibilityName(for pad: SimonPad) -> String {
        switch pad {
        case .green: return "Green"
        case .red: return "Red"
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Group {
                if vm.isPlayingBack && !vm.acceptingInput {
                    Label("Watch", systemImage: "eye")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.10), in: Capsule())
                } else if vm.acceptingInput {
                    Label("Your turn", systemImage: "hand.tap")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.10), in: Capsule())
                } else if vm.isGameOver {
                    Label("Tap Play Again", systemImage: "arrow.clockwise")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.10), in: Capsule())
                } else {
                    Label("Ready", systemImage: "play.fill")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.10), in: Capsule())
                }
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white.opacity(0.96))

            Spacer()

            Button {
                vm.newGame()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Restart")
                }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    SimonGameView()
}
