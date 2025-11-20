import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss

    // Lightweight model describing each available game
    private struct GameItem: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let destination: AnyView
    }

    // List of games discovered in the project (manually enumerated)
    private var games: [GameItem] {
        [
            GameItem(title: "Memory", systemImage: "rectangle.on.rectangle.angled", destination: AnyView(MemoryGameView())),
            GameItem(title: "Simon", systemImage: "square.grid.2x2.fill", destination: AnyView(SimonGameView())),
            GameItem(title: "Snake", systemImage: "s.square.fill", destination: AnyView(SnakeGameView()))
        ]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color("blue1"), Color("blue2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                GradientTitle("Game")

                // Games list
                VStack(spacing: 12) {
                    ForEach(games) { game in
                        NavigationLink {
                            game.destination
                                .toolbar(.hidden, for: .navigationBar)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: game.systemImage)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .frame(width: 32, height: 32)
                                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                                Text(game.title)
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.96))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                GlassBackground(cornerRadius: 14)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Open \(game.title)"))
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 24)

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
}

#Preview {
    NavigationStack { GameView() }
}
