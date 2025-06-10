import SwiftUI

public struct LiquidGlassView: View {
    let cornerRadius: CGFloat
    let updateMode: SnapshotUpdateMode
    let blurScale: CGFloat

    public init(cornerRadius: CGFloat = 20, updateMode: SnapshotUpdateMode = .continuous(), blurScale: CGFloat = 0.5) {
        self.cornerRadius = cornerRadius
        self.updateMode = updateMode
        self.blurScale = blurScale
    }

    public var body: some View {
        MetalShaderView(cornerRadius: cornerRadius, blurScale: 0.5, updateMode: updateMode)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius * 0.32))
    }
}
