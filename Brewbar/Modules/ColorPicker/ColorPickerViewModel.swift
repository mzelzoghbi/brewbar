import AppKit
import SwiftUI

struct PickedColor: Identifiable, Equatable {
    let id = UUID()
    let color: NSColor
    let date: Date

    var hex: String {
        let r = Int(round(color.redComponent * 255))
        let g = Int(round(color.greenComponent * 255))
        let b = Int(round(color.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    var rgb: String {
        let r = Int(round(color.redComponent * 255))
        let g = Int(round(color.greenComponent * 255))
        let b = Int(round(color.blueComponent * 255))
        return "rgb(\(r), \(g), \(b))"
    }

    var rgba: String {
        let r = Int(round(color.redComponent * 255))
        let g = Int(round(color.greenComponent * 255))
        let b = Int(round(color.blueComponent * 255))
        return "rgba(\(r), \(g), \(b), 1.0)"
    }

    var hsl: String {
        let r = color.redComponent
        let g = color.greenComponent
        let b = color.blueComponent

        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        let l = (maxC + minC) / 2

        guard delta > 0 else {
            return "hsl(0, 0%, \(Int(round(l * 100)))%)"
        }

        let s = l > 0.5 ? delta / (2 - maxC - minC) : delta / (maxC + minC)

        var h: CGFloat
        if maxC == r {
            h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxC == g {
            h = (b - r) / delta + 2
        } else {
            h = (r - g) / delta + 4
        }
        h = h * 60
        if h < 0 { h += 360 }

        return "hsl(\(Int(round(h))), \(Int(round(s * 100)))%, \(Int(round(l * 100)))%)"
    }

    var swiftUI: String {
        let r = color.redComponent
        let g = color.greenComponent
        let b = color.blueComponent
        return String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)", r, g, b)
    }

    var uiKit: String {
        let r = color.redComponent
        let g = color.greenComponent
        let b = color.blueComponent
        return String(format: "UIColor(red: %.3f, green: %.3f, blue: %.3f, alpha: 1.0)", r, g, b)
    }

    var cssVar: String {
        hex.lowercased()
    }

    var swiftUIColor: Color {
        Color(nsColor: color)
    }

    static func == (lhs: PickedColor, rhs: PickedColor) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class ColorPickerViewModel: ObservableObject {
    @Published var currentColor: PickedColor?
    @Published var history: [PickedColor] = []
    @Published var isPicking: Bool = false

    private let maxHistory = 5

    func pickColor() {
        isPicking = true

        // Use NSColorSampler to pick a color from anywhere on screen
        let sampler = NSColorSampler()
        sampler.show { [weak self] selectedColor in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPicking = false
                guard let selectedColor else { return }

                // Convert to sRGB color space for consistent component values
                guard let rgbColor = selectedColor.usingColorSpace(.sRGB) else { return }

                let picked = PickedColor(color: rgbColor, date: Date())
                self.currentColor = picked

                // Add to history, keep max 5
                self.history.insert(picked, at: 0)
                if self.history.count > self.maxHistory {
                    self.history = Array(self.history.prefix(self.maxHistory))
                }

                // Open popover to show the picked color
                AppDelegate.shared?.showPopover(selectingModule: "color-picker")
            }
        }
    }
}
