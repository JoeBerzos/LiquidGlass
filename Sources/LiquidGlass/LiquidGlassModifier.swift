import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let updateMode: SnapshotUpdateMode
    
    @State var size: CGSize = .zero

    public func body(content: Content) -> some View {
        content
            .background(LiquidGlassView(cornerRadius: cornerRadius, updateMode: updateMode))
    }
}

public extension View {
    func liquidGlassBackground(cornerRadius: CGFloat = 20, updateMode: SnapshotUpdateMode = .continuous()) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, updateMode: updateMode))
    }
}
