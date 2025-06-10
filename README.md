# LiquidGlass

<p align="center">
  <img src="Docs/logo.png" width="240" alt="LiquidGlass logo" />
</p>

> **Real‑time frosted glass and liquid‑like refraction for any SwiftUI view – no screenshots, no boilerplate.**

<p align="center">
  <img src="Docs/preview.gif" alt="LiquidGlass demo" width="640" />
</p>

<p align="center">
  <a href="https://swiftpackageindex.com/YourOrg/LiquidGlassSwift"><img src="https://img.shields.io/badge/Swift_Package-Compatible-5E5E5E?style=for-the-badge&logo=swift"/></a>
  <img src="https://img.shields.io/badge/iOS‑14%2B-blue?style=for-the-badge&logo=apple"/>
  <img src="https://img.shields.io/badge/Swift‑5.9-orange?style=for-the-badge&logo=swift"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge"/>
</p>

---

## ✨ Features

|                              |                                                                                                    |
| ---------------------------- | -------------------------------------------------------------------------------------------------- |
| 🔍 **Zero screenshots**      | Background is captured automatically – just drop `.liquidGlassBackground()` on any view.           |
| ⚡ **Real‑time**              | Optimised `MTLTexture` snapshots + lazy redraw; redraws only when the background actually changes. |
| 🛠 **Flexible update modes** | `.continuous`, `.once`, `.manual` via the `liquidGlassUpdateMode(_:)` modifier.                    |
| 🧩 **Pure SwiftUI**          | Works seamlessly in both worlds.                                                                   |
| 💤 **Battery‑friendly**      | MTKView stays paused until the provider notifies it – no wasted frames.                            |

## 🛠 Installation

Add *LiquidGlassSwift* through Swift Package Manager:

```text
https://github.com/YourOrg/LiquidGlassSwift.git
```

Or via **Xcode » Package Dependencies…**
Select ***LiquidGlassSwift*** and you’re done.

## 🚀 Quick start (SwiftUI)

```swift
struct GlassButton: View {
    var body: some View {
        Button {
            print("Tapped")
        } label: {
            Label("Play", systemImage: "play.fill")
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .liquidGlassBackground()          // << here
        )
        .liquidGlassUpdateMode(.continuous(interval: 0.1))
    }
}
```

## 🖼 Example

<p align="center">
  <img src="Docs/example.gif" width="640" alt="LiquidGlass live example" />
</p>

```swift
ZStack {
    AnimatedColorsMeshGradientView()

    VStack(spacing: 20) {
        Text("Liquid Glass Button")
            .font(.title.bold())
            .foregroundColor(.white)

        Button("Click Me 🔥") {
            print("Tapped")
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding()
        .liquidGlassBackground(cornerRadius: 60)
    }
}
```

## ⚙️ Update modes

| Mode                     | What it does                              | Best for                                    |
| ------------------------ | ----------------------------------------- | ------------------------------------------- |
| `.continuous(interval:)` | Captures every *n* seconds.               | Animating backgrounds, parallax, fancy UIs. |
| `.once`                  | Captures exactly one frame.               | Static dialogs, settings sheets.            |
| `.manual`                | Capture only when you call `invalidate()` | Power‑saving, custom triggers.              |

Via **SwiftUI**:

```swift
.liquidGlassBackground(updateMode: .once)
```

## 🎨 Shader & Customisation

* **Fragment shader** – tweak `Sources/LiquidGlassSwift/Shaders/LiquidGlassShader.metal` to adjust blur radius, refraction strength, tint or chromatic aberration. Two editable functions:
  * `sampleBackground()` – distort UVs / add ripple
  * `postProcess()` – lift saturation, add tint, vignette, bloom.
* **Blur margin** – `blurMargin` controls how many extra pixels the snapshot grabs around the glass (avoid edge streaks for strong blur).
* **Performance knobs** – lower snapshot interval, switch to `.once`, or optimise shader loops.

## 📈 Performance notes

* Snapshot covers only the area behind the glass – minimal memory.
* Layers above the glass are never hidden → no flicker.
* Lazy redraw means nearly zero GPU when nothing changes.

## 🙋‍♂️ FAQ

> **The glass doesn’t update when I scroll.**  
> Use `.continuous(interval: 0.016)` (≈60 fps) or trigger `.manual`’s `invalidate()` in `scrollViewDidScroll`.

> **Can I use it on macOS?**  
> Camera‑ready! The provider uses UIKit APIs, so a macOS port would need `NSImage` + `CALayer.render(in:)`.

## 🛡 License

MIT © 2025 • Your Name / YourOrg

---

**Made with ❤️ & Metal**

```
