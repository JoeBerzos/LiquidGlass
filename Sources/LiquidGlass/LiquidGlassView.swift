import SwiftUI

public struct LiquidGlassView: View {
    let cornerRadius: CGFloat
    let updateMode: SnapshotUpdateMode

    public init(cornerRadius: CGFloat = 20, updateMode: SnapshotUpdateMode = .continuous()) {
        self.cornerRadius = cornerRadius
        self.updateMode = updateMode
    }

    public var body: some View {
        MetalShaderView(cornerRadius: cornerRadius, updateMode: updateMode)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius * 0.32))
    }
}
