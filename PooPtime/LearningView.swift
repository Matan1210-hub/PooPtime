import SwiftUI

struct LearningView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color("blue1"), Color("blue2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                GradientTitle("Learning")

                // Placeholder content area
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
    NavigationStack { LearningView() }
}
