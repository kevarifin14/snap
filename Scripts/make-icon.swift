// Renders the Snap app icon. Usage: swift Scripts/make-icon.swift <out.png> [size]
import AppKit

let out = CommandLine.arguments[1]
let size = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2])! : 1024
let s = size / 1024

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> NSRect { NSRect(x: x * s, y: y * s, width: w * s, height: h * s) }
func color(_ hex: UInt32, _ a: Double = 1) -> NSColor {
    NSColor(srgbRed: Double(hex >> 16 & 0xff) / 255, green: Double(hex >> 8 & 0xff) / 255, blue: Double(hex & 0xff) / 255, alpha: a)
}

// Background squircle (Apple icon grid: 824pt body inside 1024 canvas)
let body = NSBezierPath(roundedRect: rect(100, 100, 824, 824), xRadius: 185 * s, yRadius: 185 * s)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = color(0x000000, 0.3)
shadow.shadowBlurRadius = 24 * s
shadow.shadowOffset = NSSize(width: 0, height: -10 * s)
shadow.set()
color(0x000000).setFill()
body.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: color(0x5B6CFF), ending: color(0x1E1B4B))!.draw(in: body, angle: -60)

// Screen outline
let screen = rect(210, 250, 604, 524)
let screenPath = NSBezierPath(roundedRect: screen, xRadius: 56 * s, yRadius: 56 * s)
color(0xFFFFFF, 0.08).setFill()
screenPath.fill()
color(0xFFFFFF, 0.35).setStroke()
screenPath.lineWidth = 14 * s
screenPath.stroke()

// Right half: empty slot (dashed)
let slot = NSBezierPath(roundedRect: rect(536, 290, 238, 444), xRadius: 30 * s, yRadius: 30 * s)
color(0xFFFFFF, 0.4).setStroke()
slot.lineWidth = 10 * s
slot.setLineDash([28 * s, 20 * s], count: 2, phase: 0)
slot.lineCapStyle = .round
slot.stroke()

// Left half: the snapped window
let win = rect(250, 290, 254, 444)
let winPath = NSBezierPath(roundedRect: win, xRadius: 30 * s, yRadius: 30 * s)
NSGraphicsContext.saveGraphicsState()
let glow = NSShadow()
glow.shadowColor = color(0x000000, 0.35)
glow.shadowBlurRadius = 30 * s
glow.shadowOffset = NSSize(width: 0, height: -8 * s)
glow.set()
NSGradient(starting: color(0xFFFFFF), ending: color(0xDDE3FF))!.draw(in: winPath, angle: -90)
NSGraphicsContext.restoreGraphicsState()

// Title bar dots
for (i, hex) in [0xFF5F57, 0xFEBC2E, 0x28C840].enumerated() {
    color(UInt32(hex)).setFill()
    NSBezierPath(ovalIn: rect(282 + Double(i) * 44, 680, 26, 26)).fill()
}

// Content lines
color(0x1E1B4B, 0.18).setFill()
for (i, w) in [190.0, 150, 170, 120].enumerated() {
    NSBezierPath(roundedRect: rect(282, 610 - Double(i) * 56, w, 22), xRadius: 11 * s, yRadius: 11 * s).fill()
}

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
