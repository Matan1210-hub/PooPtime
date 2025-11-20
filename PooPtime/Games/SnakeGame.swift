import SwiftUI
import Combine

// MARK: - Model

public struct Position: Hashable {
    let x: Int
    let y: Int
}

enum Direction {
    case up, down, left, right
}

// MARK: - GameViewModel / Logic

@MainActor
final class SnakeGameViewModel: ObservableObject {
    // Grid configuration
    let columns: Int
    let rows: Int

    // Published game state
    @Published private(set) var snake: [Position] = []
    @Published private(set) var direction: Direction = .right
    @Published private(set) var food: Position = Position(x: 5, y: 5)
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var score: Int = 0

    // Timer
    private var timer: AnyCancellable?
    private var tickInterval: TimeInterval

    // Input buffer to avoid multiple turns within a single tick
    private var nextDirection: Direction?

    init(columns: Int = 16, rows: Int = 24, tickInterval: TimeInterval = 0.18) {
        self.columns = max(8, columns)
        self.rows = max(12, rows)
        self.tickInterval = tickInterval
        resetGame()
    }

    func start() {
        stop()
        timer = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func resetGame() {
        stop()
        // Start snake centered horizontally, mid vertically with length 3
        let startX = columns / 3
        let startY = rows / 2
        snake = [
            Position(x: startX + 2, y: startY),
            Position(x: startX + 1, y: startY),
            Position(x: startX, y: startY)
        ]
        direction = .right
        nextDirection = nil
        isGameOver = false
        score = 0
        spawnFood()
        start()
    }

    // Handle user input: prevent reversing directly into the snake's neck
    func setDirection(_ newDirection: Direction) {
        guard !isGameOver else { return }

        // Determine the direction to compare against: either the buffered nextDirection or current direction
        let current = nextDirection ?? direction
        guard !isOpposite(newDirection, current) else { return }

        // Only accept one direction change per tick
        nextDirection = newDirection
    }

    private func isOpposite(_ a: Direction, _ b: Direction) -> Bool {
        switch (a, b) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return true
        default:
            return false
        }
    }

    private func tick() {
        guard !isGameOver, let head = snake.first else { return }

        // Apply any buffered direction change at the start of a tick
        if let buffered = nextDirection {
            direction = buffered
            nextDirection = nil
        }

        let newHead = nextHeadPosition(from: head, moving: direction)

        // Collision with walls
        guard newHead.x >= 0, newHead.x < columns, newHead.y >= 0, newHead.y < rows else {
            gameOver()
            return
        }

        // Collision with self (excluding the last tail segment which will move unless we eat)
        let willEat = (newHead == food)
        let bodyToCheck = willEat ? snake : Array(snake.dropLast())
        guard !bodyToCheck.contains(newHead) else {
            gameOver()
            return
        }

        // Advance snake
        var newSnake = snake
        newSnake.insert(newHead, at: 0)
        if willEat {
            score += 1
            snake = newSnake
            spawnFood()
        } else {
            newSnake.removeLast()
            snake = newSnake
        }
    }

    private func nextHeadPosition(from head: Position, moving dir: Direction) -> Position {
        switch dir {
        case .up: return Position(x: head.x, y: head.y - 1)
        case .down: return Position(x: head.x, y: head.y + 1)
        case .left: return Position(x: head.x - 1, y: head.y)
        case .right: return Position(x: head.x + 1, y: head.y)
        }
    }

    private func gameOver() {
        isGameOver = true
        stop()
    }

    private func spawnFood() {
        // Find an empty cell randomly
        var emptyPositions: [Position] = []
        emptyPositions.reserveCapacity(columns * rows - snake.count)
        let snakeSet = Set(snake)
        for y in 0..<rows {
            for x in 0..<columns {
                let p = Position(x: x, y: y)
                if !snakeSet.contains(p) {
                    emptyPositions.append(p)
                }
            }
        }
        if let pos = emptyPositions.randomElement() {
            food = pos
        } else {
            // No empty cells => player wins; mark as game over
            isGameOver = true
            stop()
        }
    }
}

// MARK: - SwiftUI View

public struct SnakeGameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SnakeGameViewModel()

    public init() {}

    public var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 12) {
                header
                gameBoard
                controls
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(.sRGB, red: 0.10, green: 0.16, blue: 0.28, opacity: 1.0),
                        Color(.sRGB, red: 0.06, green: 0.10, blue: 0.18, opacity: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            // Swipe gestures
            .gesture(DragGesture(minimumDistance: 10).onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > abs(dy) {
                    vm.setDirection(dx > 0 ? .right : .left)
                } else {
                    vm.setDirection(dy > 0 ? .down : .up)
                }
            })
            .onAppear { vm.start() }
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
                    .frame(width: 44, height: 44)
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
            Text("Snake")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Text("Score: \(vm.score)")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            Button(action: { vm.resetGame() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .padding(.leading, 8)
        }
    }

    private var gameBoard: some View {
        GeometryReader { geo in
            ZStack {
                // Grid background
                let cellSize = cellLength(for: geo.size)
                let boardSize = CGSize(width: cellSize * CGFloat(vm.columns),
                                       height: cellSize * CGFloat(vm.rows))

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.black.opacity(0.15))
                    .overlay(
                        // Subtle grid lines
                        gridOverlay(cellSize: cellSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    )
                    .frame(width: boardSize.width, height: boardSize.height)

                // Food
                Rectangle()
                    .fill(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                    .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                    .cornerRadius(cellSize * 0.18)
                    .position(pointPosition(vm.food, cellSize: cellSize, boardSize: boardSize))

                // Snake body
                ForEach(Array(vm.snake.enumerated()), id: \.offset) { index, segment in
                    let isHead = index == 0
                    let color: Color = isHead ? .green : .green.opacity(0.7)
                    RoundedRectangle(cornerRadius: cellSize * 0.22, style: .continuous)
                        .fill(color)
                        .overlay(
                            isHead ?
                                RoundedRectangle(cornerRadius: cellSize * 0.22, style: .continuous)
                                .stroke(.white.opacity(0.6), lineWidth: 1.2)
                                : nil
                        )
                        .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                        .position(pointPosition(segment, cellSize: cellSize, boardSize: boardSize))
                        .shadow(color: .black.opacity(0.2), radius: isHead ? 4 : 2, x: 0, y: 2)
                }

                // Game over overlay
                if vm.isGameOver {
                    VStack(spacing: 10) {
                        Text("Game Over")
                            .font(.system(.title, design: .rounded).weight(.bold))
                        Text("Score: \(vm.score)")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.secondary)
                        Button("Play Again") {
                            vm.resetGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(radius: 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
    }

    private var controls: some View {
        // On-screen directional buttons (for accessibility and simulators)
        HStack(spacing: 24) {
            Spacer()
            VStack(spacing: 16) {
                Button { vm.setDirection(.up) } label: {
                    controlButtonLabel(system: "chevron.up")
                }
                HStack(spacing: 16) {
                    Button { vm.setDirection(.left) } label: {
                        controlButtonLabel(system: "chevron.left")
                    }
                    Button { vm.setDirection(.down) } label: {
                        controlButtonLabel(system: "chevron.down")
                    }
                    Button { vm.setDirection(.right) } label: {
                        controlButtonLabel(system: "chevron.right")
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func controlButtonLabel(system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func cellLength(for size: CGSize) -> CGFloat {
        let maxWidth = size.width
        let maxHeight = size.height
        let cellW = floor(maxWidth / CGFloat(vm.columns))
        let cellH = floor(maxHeight / CGFloat(vm.rows))
        return max(8, min(cellW, cellH))
    }

    private func pointPosition(_ p: Position, cellSize: CGFloat, boardSize: CGSize) -> CGPoint {
        let centeredX = (CGFloat(p.x) + 0.5) * cellSize
        let centeredY = (CGFloat(p.y) + 0.5) * cellSize
        return CGPoint(x: centeredX, y: centeredY)
    }

    private func gridOverlay(cellSize: CGFloat) -> some View {
        Canvas { context, size in
            let cols = Int(size.width / cellSize)
            let rows = Int(size.height / cellSize)
            let lineColor = Color.white.opacity(0.08)

            var path = Path()
            // Vertical lines
            for c in 0...cols {
                let x = CGFloat(c) * cellSize
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            // Horizontal lines
            for r in 0...rows {
                let y = CGFloat(r) * cellSize
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(lineColor), lineWidth: 1)
        }
    }
}

#Preview {
    SnakeGameView()
}
