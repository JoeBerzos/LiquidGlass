import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let updateMode: SnapshotUpdateMode
    let blurScale: CGFloat
    
    @State var size: CGSize = .zero

    public func body(content: Content) -> some View {
        content
            .background(LiquidGlassView(cornerRadius: cornerRadius, updateMode: updateMode, blurScale: blurScale))
    }
}

public extension View {
    func liquidGlassBackground(
        cornerRadius: CGFloat = 20,
        updateMode: SnapshotUpdateMode = .continuous(),
        blurScale: CGFloat = 0.5
    ) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, updateMode: updateMode, blurScale: blurScale))
    }
}
