// ABOUTME: Brand colors and menu-dot helpers for CodingHarness.
// ABOUTME: Keeps UI theming out of the model while giving every harness a single source of truth.

import AppKit
import SwiftUI

extension CodingHarness {
    private static let claudeRGB = (0.851, 0.467, 0.341) // #D97757
    private static let openRGB = (0.298, 0.561, 0.839)

    var brandNSColor: NSColor {
        let rgb = self == .claudeCode ? Self.claudeRGB : Self.openRGB
        return NSColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
    }

    var brandColor: Color {
        Color(nsColor: brandNSColor)
    }

    func makeBrandDotImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 12, height: 12), flipped: false) { _ in
            self.brandNSColor.setFill()
            NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 8, height: 8)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
