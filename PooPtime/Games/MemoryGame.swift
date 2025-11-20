import SwiftUI
import Combine

// MARK: - Model

struct MemoryCard<Content: Hashable>: Identifiable {
    let id: UUID
    let content: Content
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

enum MemoryContentSet: CaseIterable {
    case symbols
    case emojis

    var items: [String] {
        switch self {
        case .symbols:
            return [
                "leaf.fill", "flame.fill", "bolt.fill", "moon.fill",
                "heart.fill", "star.fill", "cloud.fill", "umbrella.fill",
                "paperplane.fill", "scissors", "hare.fill", "tortoise.fill",
                "car.fill", "bicycle", "tram.fill", "ferry.fill"
            ]
        case .emojis:
            return ["🍎","🍌","🍇","🍓","🍒","🍑","🍍","🥝","🍉","🥥","🥕","🌽","🍄","🥐","🍩","🍪"]
        }
    }
}

// MARK: - ViewModel

@MainActor
final class MemoryGameViewModel: ObservableObject {
    @Published private(set) var cards: [MemoryCard<String>] = []
    @Published private(set) var score: Int = 0
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var statusText: String = "Ready"
    @Published private(set) var moves: Int = 0

    // Game configuration
    private var pairsCount: Int
    private var contentSet: MemoryContentSet

    // Selection state
    private var indexOfFirstSelected: Int? = nil
    private var flipBackWorkItem: DispatchWorkItem?

    init(pairsCount: Int = 8, contentSet: MemoryContentSet = .symbols) {
        self.pairsCount = max(2, min(12, pairsCount))
        self.contentSet = contentSet
        startNewGame()
    }

    func startNewGame(pairsCount: Int? = nil, contentSet: MemoryContentSet? = nil) {
        if let p = pairsCount { self.pairsCount = max(2, min(12, p)) }
        if let set = contentSet { self.contentSet = set }

        score = 0
        moves = 0
        isGameOver = false
        statusText = "Memorize the cards"

        flipBackWorkItem?.cancel()
        indexOfFirstSelected = nil

        // Build deck
        var chosenContents = Array(self.contentSet.items.shuffled().prefix(self.pairsCount))
        // If emojis set is chosen, contents are already strings; symbols are also string names.
        var deck: [MemoryCard<String>] = []
        for content in chosenContents {
            deck.append(MemoryCard(id: UUID(), content: content))
            deck.append(MemoryCard(id: UUID(), content: content))
        }
        cards = deck.shuffled()

        // Brief reveal (optional): flash all face up, then flip down
        Task {
            await brieflyRevealAll()
            statusText = "Find all pairs"
        }
    }

    private func brieflyRevealAll() async {
        for i in cards.indices {
            cards[i].isFaceUp = true
        }
        try? await Task.sleep(nanoseconds: 700_000_000)
        for i in cards.indices {
            if !cards[i].isMatched {
                cards[i].isFaceUp = false
            }
        }
    }

    func tapCard(_ card: MemoryCard<String>) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }),
              !cards[index].isFaceUp,
              !cards[index].isMatched,
              !isGameOver else { return }

        // Cancel any pending flip-back action if user acts quickly
        flipBackWorkItem?.cancel()

        // Flip selected card
        cards[index].isFaceUp = true

        if let firstIndex = indexOfFirstSelected {
            // Second selection
            moves += 1
            indexOfFirstSelected = nil
            checkForMatch(firstIndex: firstIndex, secondIndex: index)
        } else {
            // First selection
            indexOfFirstSelected = index
            statusText = "Pick another card"
        }
    }

    private func checkForMatch(firstIndex: Int, secondIndex: Int) {
        let first = cards[firstIndex]
        let second = cards[secondIndex]
        if first.content == second.content {
            // Match
            score += 1
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            statusText = "Nice! It's a match"
            checkGameOver()
        } else {
            statusText = "Not a match"
            // Schedule flip back after a short delay to let player see
            let work = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    guard let self = self else { return }
                    if self.cards.indices.contains(firstIndex) {
                        self.cards[firstIndex].isFaceUp = false
                    }
                    if self.cards.indices.contains(secondIndex) {
                        self.cards[secondIndex].isFaceUp = false
                    }
                    self.statusText = "Try again"
                }
            }
            flipBackWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: work)
        }
    }

    private func checkGameOver() {
        if cards.allSatisfy({ $0.isMatched }) {
            isGameOver = true
            statusText = "Completed!"
        }
    }
}

// MARK: - View

public struct MemoryGameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = MemoryGameViewModel()

    public init() {}

    public var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 16) {
                header
                grid
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
            Text("Memory")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Text("Score: \(vm.score)")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            Button {
                vm.startNewGame()
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

    private var grid: some View {
        GeometryReader { geo in
            let columns = idealColumns(for: geo.size)
            let spacing: CGFloat = 10
            let cell = cellSize(for: geo.size, columns: columns, spacing: spacing)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.black.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                    ForEach(vm.cards) { card in
                        cardView(card, size: cell)
                            .frame(width: cell, height: cell * 1.2)
                            .onTapGesture { vm.tapCard(card) }
                            .accessibilityLabel(cardAccessibility(card))
                            .animation(.easeInOut(duration: 0.18), value: card.isFaceUp)
                            .animation(.easeInOut(duration: 0.18), value: card.isMatched)
                    }
                }
                .padding(12)

                if vm.isGameOver {
                    VStack(spacing: 10) {
                        Text("You Win!")
                            .font(.system(.title, design: .rounded).weight(.bold))
                        Text("Moves: \(vm.moves)")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.secondary)
                        Button("Play Again") {
                            vm.startNewGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(radius: 8)
                }
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
    }

    private func cardView(_ card: MemoryCard<String>, size: CGFloat) -> some View {
        ZStack {
            // Back
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.9), .pink.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .opacity(card.isFaceUp ? 0.0 : 1.0)

            // Face
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black.opacity(0.06), lineWidth: 1)
                )
                .overlay(
                    contentLabel(for: card)
                        .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .opacity(card.isMatched ? 0.3 : 1.0)
                )
                .opacity(card.isFaceUp ? 1.0 : 0.0)
        }
        .rotation3DEffect(.degrees(card.isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .scaleEffect(card.isMatched ? 0.96 : 1.0)
        .shadow(color: .black.opacity(card.isFaceUp ? 0.18 : 0.28), radius: card.isFaceUp ? 8 : 10, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func contentLabel(for card: MemoryCard<String>) -> some View {
        // Use SF Symbols or emoji content
        if card.content.count == 1, let first = card.content.unicodeScalars.first, first.properties.isEmoji {
            return AnyView(Text(card.content))
        } else {
            return AnyView(Image(systemName: card.content))
        }
    }

    private func cardAccessibility(_ card: MemoryCard<String>) -> Text {
        let state = card.isMatched ? "matched" : (card.isFaceUp ? "face up" : "face down")
        return Text("Card \(state)")
    }

    private func idealColumns(for size: CGSize) -> Int {
        // Prefer 4 columns in portrait-like sizes, 6 in wide
        if size.width > size.height * 0.8 { return 6 }
        return 4
    }

    private func cellSize(for size: CGSize, columns: Int, spacing: CGFloat) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columns - 1) + 24 // grid padding
        let width = size.width - totalSpacing
        return max(56, floor(width / CGFloat(columns)))
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Label(vm.statusText, systemImage: statusIcon)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.10), in: Capsule())
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.96))

            Spacer()

            Button {
                vm.startNewGame()
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

    private var statusIcon: String {
        if vm.isGameOver { return "checkmark.seal.fill" }
        switch vm.statusText {
        case "Pick another card": return "hand.tap"
        case "Not a match", "Try again": return "xmark.circle"
        case "Nice! It's a match": return "sparkles"
        default: return "play.fill"
        }
    }
}

#Preview {
    MemoryGameView()
}
