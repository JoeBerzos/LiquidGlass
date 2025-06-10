import UIKit
import SwiftUI
import Metal
import MetalKit

/// Describes how often the background snapshot should be refreshed.
public enum SnapshotUpdateMode {
    /// Captures every *interval* seconds (default ≈ 5 fps).
    case continuous(interval: TimeInterval = 0.2)
    /// Captures exactly once and re‑uses the texture forever.
    case once
    /// Captures only when you call `invalidate()` (the lightest option).
    case manual
}

/// Captures a Metal texture of whatever is **behind** the LiquidGlass view so
/// that the fragment shader can refract it. After this rewrite you *never*
/// need to think about screenshots – just add `.liquidGlassBackground()`.
@MainActor
public final class BackgroundTextureProvider {

    // MARK: – Public API
    public var updateMode: SnapshotUpdateMode = .continuous() {
        didSet { resetTimer() }
    }
    
    public var didUpdateTexture: (() -> Void)?

    /// Use when `updateMode == .manual` and the layout behind the glass changed.
    public func invalidate() {
        cachedTexture = nil
        lastCaptureTime = 0
    }

    /// Returns the latest texture (captures one if needed).
    public func currentTexture(for view: UIView) -> MTLTexture? {
        if timerTarget !== view { timerTarget = view }

        if let cached = cachedTexture { return cached }
        cachedTexture = makeSnapshotTexture(from: view)
        lastCaptureTime = CFAbsoluteTimeGetCurrent()
        return cachedTexture
    }

    // MARK: – Initialisation
    
    public init(device: MTLDevice) {
        self.device = device
        self.textureLoader = MTKTextureLoader(device: device)
        resetTimer()
    }
    
    // MARK: – Private
    
    private let device: MTLDevice
    private let textureLoader: MTKTextureLoader

    private var cachedTexture: MTLTexture? {
        didSet {
            didUpdateTexture?()
        }
    }
    private var lastCaptureTime: CFAbsoluteTime = 0

    private weak var timerTarget: UIView?
    private var timer: Timer?
    private var isCapturingSnapshot = false

    private func resetTimer() {
        timer?.invalidate()
        switch updateMode {
        case .continuous(let interval):
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self]  _ in
                Task { @MainActor in
                    guard let self, let view = self.timerTarget else { return }
                    self.cachedTexture = self.makeSnapshotTexture(from: view)
                    self.lastCaptureTime = CFAbsoluteTimeGetCurrent()
                }
            }
        case .once, .manual:
            timer = nil
        }
    }
    
    @MainActor private func makeSnapshotTexture(from view: UIView) -> MTLTexture? {
        if isCapturingSnapshot { return cachedTexture }
        isCapturingSnapshot = true
        defer { isCapturingSnapshot = false }
        
        if let cg = snapshotBehind(view) {
            return try? textureLoader.newTexture(cgImage: cg, options: [.SRGB: false])
        }
        return nil
    }
    
    @MainActor private func snapshotBehind(_ glass: UIView) -> CGImage? {
        guard let window = glass.window else { return nil }

        let rect = glass.convert(glass.bounds, to: window)

        let renderer = UIGraphicsImageRenderer(size: rect.size, format: .init())
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.translateBy(x: -rect.origin.x, y: -rect.origin.y)

            var target: CALayer = glass.layer

            var chain: [CALayer] = []
            while target !== window.layer {
                guard let parent = target.superlayer else { break }
                chain.append(target)
                target = parent
            }
            chain.reverse()

            var levelParent = window.layer
            for wanted in chain {
                guard let idx = levelParent.sublayers?.firstIndex(of: wanted) else { break }
                for i in 0..<idx {
                    levelParent.sublayers?[i].render(in: cg)
                }
                levelParent = wanted
            }
        }
        return img.cgImage
    }
}
