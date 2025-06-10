<p align="center">
  <img src="Docs/Logo.png" width="380" alt="LiquidGlass logo" />
</p>

> **Real‑time frosted glass and liquid‑like refraction for any SwiftUI view – no screenshots, no boilerplate.**

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
| 🔍 **Zero screenshots**      | Background is captured automatically – just drop `liquidGlassBackground` on any view.           |
| ⚡ **Real‑time**              | Optimised `MTLTexture` snapshots + lazy redraw; redraws only when the background actually changes. |
| 🛠 **Flexible update modes** | `.continuous`, `.once`, `.manual` via the `updateMode` modifier.                    |
| 🧩 **Pure SwiftUI**          | Works seamlessly in both worlds.                                                                   |
| 💤 **Battery‑friendly**      | MTKView stays paused until the provider notifies it – no wasted frames.                            |

## 🛠 Installation

Add *LiquidGlass* through Swift Package Manager:

```text
https://github.com/BarredEwe/LiquidGlass.git
```

Or via **Xcode » Package Dependencies…**
Select ***LiquidGlass*** and you’re done.

## 🚀 Quick start (SwiftUI)

```swift
Button("Glass Text") { }
    .liquidGlassBackground(cornerRadius: 60)
```

## 🖼 Example

<table>
<tr>
<td width="50%">
  
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
</td>

<td width="50%" align="center">
  <img src="Docs/Example.gif" width="340" alt="LiquidGlass live example" />
</td>
</tr>
</table>

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

* **Fragment shader** – tweak `Sources/LiquidGlass/Shaders/LiquidGlassShader.metal` to adjust blur radius, refraction strength, tint or chromatic aberration. Two editable functions:
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

## 🛡 License

MIT © 2025 • BarredEwe / Prefire

---

**Made with ❤️ & Metal**

```
