import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let normalizedHex = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0

        guard Scanner(string: normalizedHex).scanHexInt64(&value) else {
            self = .accentColor
            return
        }

        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double

        switch normalizedHex.count {
        case 6:
            // RRGGBB
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            opacity = 1

        case 8:
            // RRGGBBAA
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            opacity = Double(value & 0xFF) / 255

        default:
            self = .accentColor
            return
        }

        self.init(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: opacity
        )
    }

    func hexString(includeAlpha: Bool = false) -> String? {
        let uiColor = UIColor(self).resolvedColor(
            with: UITraitCollection.current
        )

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(
            &red,
            green: &green,
            blue: &blue,
            alpha: &alpha
        ) else {
            return nil
        }

        let redValue = Int(round(red * 255))
        let greenValue = Int(round(green * 255))
        let blueValue = Int(round(blue * 255))
        let alphaValue = Int(round(alpha * 255))

        if includeAlpha {
            return String(
                format: "#%02X%02X%02X%02X",
                redValue,
                greenValue,
                blueValue,
                alphaValue
            )
        }

        return String(
            format: "#%02X%02X%02X",
            redValue,
            greenValue,
            blueValue
        )
    }
}
