#!/usr/bin/env swift

// Renders the MC Pocket app icon as a 1024x1024 PNG. Run with:
//     swift tools/MakeIcon.swift
//
// Pure Core Graphics + Core Text — no NSApplication needed, works from a
// plain `swift` CLI invocation. Writes to:
//     Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png

import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outputPath = "Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"

let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: Int(size) * 4,
    space: cs,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fputs("CGContext alloc failed\n", stderr); exit(1)
}

// Solid background
ctx.setFillColor(red: 0.13, green: 0.10, blue: 0.22, alpha: 1.0)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Diagonal gradient overlay
if let gradient = CGGradient(
    colorsSpace: cs,
    colors: [
        CGColor(red: 0.40, green: 0.22, blue: 0.78, alpha: 1.0),
        CGColor(red: 0.85, green: 0.36, blue: 0.55, alpha: 0.95),
    ] as CFArray,
    locations: [0.0, 1.0]
) {
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: size, y: 0),
        options: []
    )
}

// Lightning bolt + four sparkle dots, centered.
ctx.saveGState()
ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 0.94)

let centerX = size / 2
let centerY = size / 2 + 60

let bolt = CGMutablePath()
bolt.move(to: CGPoint(x: centerX - 70, y: centerY + 260))
bolt.addLine(to: CGPoint(x: centerX + 130, y: centerY + 40))
bolt.addLine(to: CGPoint(x: centerX + 10, y: centerY + 40))
bolt.addLine(to: CGPoint(x: centerX + 130, y: centerY - 260))
bolt.addLine(to: CGPoint(x: centerX - 110, y: centerY - 20))
bolt.addLine(to: CGPoint(x: centerX + 10, y: centerY - 20))
bolt.closeSubpath()
ctx.addPath(bolt)
ctx.fillPath()

let sparkleCenters: [CGPoint] = [
    .init(x: centerX - 280, y: centerY + 180),
    .init(x: centerX + 260, y: centerY + 220),
    .init(x: centerX - 240, y: centerY - 200),
    .init(x: centerX + 290, y: centerY - 140),
]
for c in sparkleCenters {
    let star = CGMutablePath()
    let r: CGFloat = 38
    let inner: CGFloat = 14
    star.move(to: CGPoint(x: c.x, y: c.y + r))
    star.addLine(to: CGPoint(x: c.x + inner, y: c.y + inner))
    star.addLine(to: CGPoint(x: c.x + r, y: c.y))
    star.addLine(to: CGPoint(x: c.x + inner, y: c.y - inner))
    star.addLine(to: CGPoint(x: c.x, y: c.y - r))
    star.addLine(to: CGPoint(x: c.x - inner, y: c.y - inner))
    star.addLine(to: CGPoint(x: c.x - r, y: c.y))
    star.addLine(to: CGPoint(x: c.x - inner, y: c.y + inner))
    star.closeSubpath()
    ctx.addPath(star)
    ctx.fillPath()
}
ctx.restoreGState()

// "MC" wordmark via Core Text (no AppKit needed).
ctx.saveGState()
let fontSize: CGFloat = 150
let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 0.92)
let attrs: [NSAttributedString.Key: Any] = [
    .init(kCTFontAttributeName as String): font,
    .init(kCTForegroundColorAttributeName as String): white,
]
let mc = NSAttributedString(string: "MC", attributes: attrs)
let line = CTLineCreateWithAttributedString(mc as CFAttributedString)
let bounds = CTLineGetImageBounds(line, ctx)
ctx.textMatrix = .identity
ctx.textPosition = CGPoint(
    x: (size - bounds.width) / 2 - bounds.origin.x,
    y: 88
)
CTLineDraw(line, ctx)
ctx.restoreGState()

guard let image = ctx.makeImage() else {
    fputs("makeImage failed\n", stderr); exit(1)
}
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(
    url as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fputs("ImageDestination failed\n", stderr); exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else {
    fputs("finalize failed\n", stderr); exit(1)
}

let attrs2 = try? FileManager.default.attributesOfItem(atPath: outputPath)
let bytes = (attrs2?[.size] as? NSNumber)?.intValue ?? 0
print("✓ wrote \(url.lastPathComponent) (\(bytes) bytes)")
