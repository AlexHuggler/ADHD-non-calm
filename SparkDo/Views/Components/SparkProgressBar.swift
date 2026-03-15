import SwiftUI

struct SparkProgressBar: View {
    let progress: Double
    var height: CGFloat = 6
    var fillStyle: AnyShapeStyle = AnyShapeStyle(SparkTheme.primaryGradient)
    var trackColor: Color = SparkTheme.cardBackground
    var shape: BarShape = .capsule

    enum BarShape {
        case capsule, roundedRect
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                switch shape {
                case .capsule:
                    Capsule()
                        .fill(trackColor)
                        .frame(height: height)

                    Capsule()
                        .fill(fillStyle)
                        .frame(width: geo.size.width * min(1, max(0, progress)), height: height)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)

                case .roundedRect:
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(trackColor)
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(fillStyle)
                        .frame(width: geo.size.width * min(1, max(0, progress)), height: height)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

#Preview {
    VStack(spacing: 20) {
        SparkProgressBar(progress: 0.6)
        SparkProgressBar(progress: 0.3, height: 16, fillStyle: AnyShapeStyle(SparkTheme.sunshineYellow), shape: .roundedRect)
        SparkProgressBar(progress: 0.8, fillStyle: AnyShapeStyle(SparkTheme.mintGreen))
    }
    .padding()
    .background(SparkTheme.darkBackground)
}
