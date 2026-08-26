// ABOUTME: Brand colors and menu-dot helpers for CodingHarness.
// ABOUTME: Keeps UI theming out of the model while giving every harness a single source of truth.

import AppKit
import SwiftUI

extension CodingHarness {
    /// Primary brand color for the harness — used for selection rings and tints.
    var brandColor: Color {
        switch self {
        case .claudeCode:
            // Anthropic coral — #D97757
            return Color(red: 0.851, green: 0.467, blue: 0.341)
        case .opencode:
            // Visor blue — sampled to match avatar_opencode_1.png
            return Color(red: 0.298, green: 0.561, blue: 0.839)
        }
    }

    /// NSColor bridge for AppKit menu-dot rendering.
    var brandNSColor: NSColor {
        switch self {
        case .claudeCode:
            return NSColor(red: 0.851, green: 0.467, blue: 0.341, alpha: 1)
        case .opencode:
            return NSColor(red: 0.298, green: 0.561, blue: 0.839, alpha: 1)
        }
    }

    /// 12×12 @2x filled-circle image in `brandNSColor`, for use in `NSMenu` items.
    /// SwiftUI `foregroundStyle` does not reliably tint `Image(systemName:)` inside menus,
    /// so we pre-render a bitmap. No cache — image creation is trivial and avoids
    /// concurrency-safety complexity under strict concurrency.
    var brandDotImage: NSImage {
        let size = NSSize(width: 12, height: 12)
        let image = NSImage(size: size)
        image.lockFocus()
        let path = NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 8, height: 8))
        brandNSColor.setFill()
        path.fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
