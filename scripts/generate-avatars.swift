#!/usr/bin/swift

// ABOUTME: Regenerates the 64x64 agent avatar PNGs in Resources/AgentSprites/
// ABOUTME: from high-resolution (1024x1024) source art.
//
// Usage:
//   swift scripts/generate-avatars.swift <source-dir> <output-dir>
//
// For each entry in the map below, loads <source-dir>/<path>, crops to the
// alpha bounding box (4% padding per axis, squared around the character,
// padded dimension = max(w, h) + 8%), downscales to exactly 64x64 with
// high-quality interpolation while preserving transparency, and writes the
// result to <output-dir>/<name>. Legacy char_<n>.png fallbacks are untouched.

import AppKit

let avatarSize = 64
let paddingFraction = 0.04 // extra margin added on each side of the character
let alphaThreshold = 3     // alpha byte >= this counts as visible (≈0.01)

/// Source path relative to <source-dir> -> output file name.
let spriteMap: [String: String] = [
    "claude_agent.png": "avatar_claude_1.png",
    "opencode_agent.png": "avatar_opencode_1.png",
    "explore_agent.png": "avatar_explore_1.png",
    "additionals/explore_2.png": "avatar_explore_2.png",
    "additionals/explore_3.png": "avatar_explore_3.png",
    "additionals/explore_4.png": "avatar_explore_4.png",
    "general_purpose_agent.png": "avatar_generalpurpose_1.png",
    "additionals/general_purpose_2.png": "avatar_generalpurpose_2.png",
    "additionals/general_purpose_3.png": "avatar_generalpurpose_3.png",
    "additionals/general_purpose_4.png": "avatar_generalpurpose_4.png",
    "plan_agent.png": "avatar_plan_1.png",
]

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: swift scripts/generate-avatars.swift <source-dir> <output-dir>\n", stderr)
    exit(2)
}
let sourceDir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputDir = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)

func fail(_ message: String) -> Never {
    fputs("error: \(message)\n", stderr)
    exit(1)
}

// MARK: - Loading

func loadBitmapRep(at url: URL) -> NSBitmapImageRep? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    if let rep = NSBitmapImageRep(data: data) { return rep }
    guard let image = NSImage(data: data),
          let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    return NSBitmapImageRep(cgImage: cg)
}

/// Wraps a rep in an NSImage whose point size equals its pixel size, so
/// drawing math works in raw pixels regardless of embedded DPI.
func pixelExactImage(from rep: NSBitmapImageRep) -> NSImage {
    rep.size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    let image = NSImage(size: rep.size)
    image.addRepresentation(rep)
    return image
}

// MARK: - Alpha bounding box

/// Bounding box of pixels whose alpha clears the threshold, in top-left
/// pixel coordinates.
func alphaBounds(of rep: NSBitmapImageRep) -> CGRect? {
    let w = rep.pixelsWide
    let h = rep.pixelsHigh
    var minX = w, minY = h, maxX = -1, maxY = -1

    if let base = rep.bitmapData, !rep.isPlanar, rep.samplesPerPixel >= 4, rep.bitsPerSample == 8 {
        let spp = rep.samplesPerPixel
        let bpr = rep.bytesPerRow
        for y in 0..<h {
            let row = base + y * bpr
            for x in 0..<w where row[x * spp + spp - 1] >= alphaThreshold {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
    } else {
        for y in 0..<h {
            for x in 0..<w where rep.colorAt(x: x, y: y)?.alphaComponent ?? 0 >= 0.01 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
    }

    guard maxX >= minX, maxY >= minY else { return nil }
    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}

// MARK: - Rendering

/// Renders `src` into a transparent square canvas of `side` pixels so that
/// the given crop rect (bottom-left pixel coords in the source) fills it.
func renderSquare(from src: NSBitmapImageRep, crop: CGRect, side: Int) -> NSBitmapImageRep? {
    guard let out = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }
    out.size = NSSize(width: side, height: side)

    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: out) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: side, height: side).fill()
    let image = pixelExactImage(from: src)
    image.draw(
        in: NSRect(x: -crop.minX, y: -crop.minY, width: CGFloat(src.pixelsWide), height: CGFloat(src.pixelsHigh)),
        from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
        operation: .copy, fraction: 1.0
    )
    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return out
}

/// Downscales a rep to a square `size`x`size` bitmap with high-quality interpolation.
func downscale(_ src: NSBitmapImageRep, to size: Int) -> NSBitmapImageRep? {
    guard let out = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }
    out.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: out) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    let image = pixelExactImage(from: src)
    image.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
        operation: .copy, fraction: 1.0
    )
    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return out
}

// MARK: - Main

do {
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
} catch {
    fail("could not create output dir \(outputDir.path): \(error)")
}

var failures = 0
for (relPath, outName) in spriteMap.sorted(by: { $0.key < $1.key }) {
    let srcURL = sourceDir.appendingPathComponent(relPath)
    let outURL = outputDir.appendingPathComponent(outName)

    guard FileManager.default.fileExists(atPath: srcURL.path) else {
        fputs("skip: missing source \(srcURL.path)\n", stderr)
        failures += 1
        continue
    }
    guard let src = loadBitmapRep(at: srcURL) else {
        fputs("skip: unreadable image \(srcURL.path)\n", stderr)
        failures += 1
        continue
    }
    guard let bounds = alphaBounds(of: src) else {
        fputs("skip: no visible pixels in \(srcURL.path)\n", stderr)
        failures += 1
        continue
    }

    // Pad the character by 4% per axis, then square the padded frame around
    // the character's center (padded dimension = max(w, h) + 8%).
    let paddedW = bounds.width * (1 + 2 * paddingFraction)
    let paddedH = bounds.height * (1 + 2 * paddingFraction)
    let side = Int(ceil(max(paddedW, paddedH)))
    let centerX = bounds.midX
    let centerYTopLeft = bounds.midY
    // Convert the top-left-origin crop to the bottom-left coords NSImage draws in.
    let crop = CGRect(
        x: centerX - CGFloat(side) / 2,
        y: CGFloat(src.pixelsHigh) - centerYTopLeft - CGFloat(side) / 2,
        width: CGFloat(side),
        height: CGFloat(side)
    )

    guard let square = renderSquare(from: src, crop: crop, side: side),
          let small = downscale(square, to: avatarSize),
          let png = small.representation(using: .png, properties: [:]) else {
        fputs("skip: rendering failed for \(srcURL.path)\n", stderr)
        failures += 1
        continue
    }

    do {
        try png.write(to: outURL)
    } catch {
        fputs("skip: could not write \(outURL.path): \(error)\n", stderr)
        failures += 1
        continue
    }
    print("wrote \(outURL.path) (\(avatarSize)x\(avatarSize), from \(src.pixelsWide)x\(src.pixelsHigh))")
}

if failures > 0 {
    fail("\(failures) sprite(s) failed")
}
print("done: \(spriteMap.count - failures)/\(spriteMap.count) avatars generated")
