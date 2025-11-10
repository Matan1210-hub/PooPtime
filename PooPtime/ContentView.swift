//
//  ContentView.swift
//  PooPtime
//
//  Created by Matan Cohen on 10/11/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("blue1"), Color("blue2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("How would you like to spend your toilet time today?")
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

                // Buttons stack
                VStack(spacing: 16) {
                    Button("Learn something quick") {
                        // TODO: Add action
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    Button("Play a short game") {
                        // TODO: Add action
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    Button("Relax with a mini meditation") {
                        // TODO: Add action
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 0)
            }
            .padding(.top, 24)
        }
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
