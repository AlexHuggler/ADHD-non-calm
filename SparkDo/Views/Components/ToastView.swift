import SwiftUI

struct ToastView: View {
    let icon: String
    let message: String
    var iconColor: Color = SparkTheme.mintGreen

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)

            Text(message)
                .font(SparkTypography.body())
                .foregroundStyle(SparkTheme.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SparkTheme.cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let icon: String
    let message: String
    var iconColor: Color = SparkTheme.mintGreen
    var duration: TimeInterval = 2.5

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresented {
                    ToastView(icon: icon, message: message, iconColor: iconColor)
                        .padding(.bottom, 32)
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(duration))
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, icon: String, message: String, iconColor: Color = SparkTheme.mintGreen, duration: TimeInterval = 2.5) -> some View {
        modifier(ToastModifier(isPresented: isPresented, icon: icon, message: message, iconColor: iconColor, duration: duration))
    }
}

#Preview {
    ZStack {
        SparkTheme.darkBackground.ignoresSafeArea()
        Text("Content")
            .foregroundStyle(.white)
    }
    .toast(isPresented: .constant(true), icon: "checkmark.circle.fill", message: "Quest completed!")
}
