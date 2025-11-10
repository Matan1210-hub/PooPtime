//
//  ContentView.swift
//  PooPtime
//
//  Created by Matan Cohen on 10/11/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var navigateToLearning = false
    @State private var bulbAnimating = false

    // New state for game button animation and navigation
    @State private var navigateToGame = false
    @State private var gameIconAnimating = false

    // New state for meditation button animation and navigation
    @State private var navigateToMeditation = false
    @State private var meditationIconAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("blue1"), Color("blue2")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    GradientTitle("How would you like to spend your toilet time today?")

                    // Buttons stack
                    VStack(spacing: 16) {
                        // Programmatic navigation for the first button so we can finish the animation first
                        ZStack {
                            Button {
                                // Start the icon animation
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    bulbAnimating = true
                                }

                                // Trigger navigation after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navigateToLearning = true
                                    // Reset animation state for when user comes back
                                    bulbAnimating = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.max")
                                        .symbolRenderingMode(.hierarchical)
                                        .imageScale(.large)
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                        .opacity(bulbAnimating ? 0.0 : 1.0)
                                        .scaleEffect(bulbAnimating ? 0.8 : 1.0)
                                        .animation(.easeInOut(duration: 0.3), value: bulbAnimating)

                                    Text("Learn something quick")
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(LiquidGlassButtonStyle())
                        }

                        // Programmatic navigation and animated icon for the Game button
                        ZStack {
                            Button {
                                // Animate the game controller icon fade-out and scale-down
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    gameIconAnimating = true
                                }

                                // Navigate after the animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navigateToGame = true
                                    // Reset animation state when coming back
                                    gameIconAnimating = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "gamecontroller")
                                        .symbolRenderingMode(.hierarchical)
                                        .imageScale(.large)
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                        .opacity(gameIconAnimating ? 0.0 : 1.0)
                                        .scaleEffect(gameIconAnimating ? 0.8 : 1.0)
                                        .animation(.easeInOut(duration: 0.3), value: gameIconAnimating)

                                    Text("Play a short game")
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(LiquidGlassButtonStyle())
                        }

                        // Programmatic navigation and animated icon for the Meditation button
                        ZStack {
                            Button {
                                // Animate the leaf icon fade-out and scale-down
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    meditationIconAnimating = true
                                }

                                // Navigate after the animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navigateToMeditation = true
                                    // Reset animation state when coming back
                                    meditationIconAnimating = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "leaf")
                                        .symbolRenderingMode(.hierarchical)
                                        .imageScale(.large)
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                        .opacity(meditationIconAnimating ? 0.0 : 1.0)
                                        .scaleEffect(meditationIconAnimating ? 0.8 : 1.0)
                                        .animation(.easeInOut(duration: 0.3), value: meditationIconAnimating)

                                    Text("Relax with a mini meditation")
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(LiquidGlassButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 0)
                }
                .padding(.top, 24)
            }
            .navigationBarHidden(true)
            // Modern programmatic navigation destinations
            .navigationDestination(isPresented: $navigateToLearning) {
                LearningView()
            }
            .navigationDestination(isPresented: $navigateToGame) {
                GameView()
            }
            .navigationDestination(isPresented: $navigateToMeditation) {
                MeditationView()
            }
        }
    }
}

// Shared title styling to ensure consistency across pages
struct GradientTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.title.bold())
            .multilineTextAlignment(.center)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color("brown1"), Color("brown2")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

// Liquid glass–style button
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let corner: CGFloat = 22
        let pressed = configuration.isPressed

        return configuration.label
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(.white.opacity(0.96))
            .frame(maxWidth: .infinity, minHeight: 72) // Large, thick block height
            .padding(.vertical, 8) // Small extra padding to enhance thickness without overflow
            .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .background(
                GlassBackground(cornerRadius: corner)
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .shadow(color: Color.black.opacity(0.22), radius: 12, x: 0, y: 8)
            .opacity(pressed ? 0.92 : 1.0)
            .scaleEffect(pressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

// Frosted/liquid glass rounded background
struct GlassBackground: View {
    var cornerRadius: CGFloat = 18

    var body: some View {
        ZStack {
            // Blur
            VisualEffectBlur(radius: 20, opaque: false)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Subtle inner gradient tint
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.18),
                            .white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Specular highlights
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.55),
                            .white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .blendMode(.overlay)
        }
        .background(
            // Outer soft shadow glow behind shape
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.white.opacity(0.06))
                .blur(radius: 6)
        )
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// UIKit-backed blur for consistent frosted effect across shapes
struct VisualEffectBlur: UIViewRepresentable {
    let radius: CGFloat
    let opaque: Bool

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // We keep the system material for dynamic vibrancy; radius is kept for API symmetry
        uiView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        uiView.isOpaque = opaque
    }
}

#Preview {
    ContentView()
}
