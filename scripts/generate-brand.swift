import AppKit
import Foundation

// Original Keynest artwork. Run from the repository root.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources")
let iconset = resources.appendingPathComponent("Keynest.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
let green = NSColor(srgbRed: 0.73, green: 0.94, blue: 0.56, alpha: 1)

func bitmap(width: Int, height: Int, draw: () -> Void) throws -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

func drawIcon(_ size: Int) {
    let cg = NSGraphicsContext.current!.cgContext
    cg.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let silhouette = NSBezierPath(roundedRect: NSRect(x: 62, y: 62, width: 900, height: 900), xRadius: 214, yRadius: 214)
    NSGradient(starting: NSColor(srgbRed: 0.17, green: 0.21, blue: 0.19, alpha: 1),
               ending: NSColor(srgbRed: 0.065, green: 0.085, blue: 0.08, alpha: 1))!.draw(in: silhouette, angle: -75)
    NSColor.white.withAlphaComponent(0.13).setStroke()
    silhouette.lineWidth = 3
    silhouette.stroke()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
    shadow.shadowBlurRadius = 35
    shadow.shadowOffset = NSSize(width: 0, height: -22)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    let key = NSBezierPath(roundedRect: NSRect(x: 226, y: 234, width: 572, height: 556), xRadius: 126, yRadius: 126)
    NSColor(srgbRed: 0.19, green: 0.25, blue: 0.19, alpha: 1).setFill()
    key.fill()
    NSGraphicsContext.restoreGraphicsState()
    green.withAlphaComponent(0.75).setStroke()
    key.lineWidth = 9
    key.stroke()
    let inner = NSBezierPath(roundedRect: NSRect(x: 254, y: 274, width: 516, height: 488), xRadius: 104, yRadius: 104)
    green.withAlphaComponent(0.035).setFill()
    inner.fill()
    green.withAlphaComponent(0.12).setStroke()
    inner.lineWidth = 3
    inner.stroke()

    // The K sits inside a keycap: a small nest for sound and focus.
    green.setStroke()
    let monogram = NSBezierPath()
    monogram.lineWidth = 54
    monogram.lineCapStyle = .round
    monogram.lineJoinStyle = .round
    monogram.move(to: NSPoint(x: 390, y: 385))
    monogram.line(to: NSPoint(x: 390, y: 645))
    monogram.move(to: NSPoint(x: 600, y: 645))
    monogram.line(to: NSPoint(x: 400, y: 505))
    monogram.line(to: NSPoint(x: 610, y: 385))
    monogram.stroke()
    green.withAlphaComponent(0.5).setFill()
    NSBezierPath(roundedRect: NSRect(x: 641, y: 484, width: 30, height: 66), xRadius: 15, yRadius: 15).fill()
}

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let size = base * scale
        let suffix = scale == 2 ? "@2x" : ""
        let data = try bitmap(width: size, height: size) { drawIcon(size) }
        try data.write(to: iconset.appendingPathComponent("icon_\(base)x\(base)\(suffix).png"))
    }
}
try bitmap(width: 1024, height: 1024) { drawIcon(1024) }.write(to: resources.appendingPathComponent("Keynest-logo.png"))

let background = try bitmap(width: 1200, height: 800) {
    let cg = NSGraphicsContext.current!.cgContext
    cg.scaleBy(x: 2, y: 2)
    NSColor(srgbRed: 0.07, green: 0.085, blue: 0.08, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 600, height: 400).fill()
    let title = NSAttributedString(string: "Keynest", attributes: [.font: NSFont.systemFont(ofSize: 34, weight: .semibold), .foregroundColor: green])
    title.draw(at: NSPoint(x: 40, y: 320))
    NSAttributedString(string: "Find your focus. · Encontre seu foco.", attributes: [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.white.withAlphaComponent(0.55)])
        .draw(at: NSPoint(x: 42, y: 295))
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 272, y: 190)); arrow.line(to: NSPoint(x: 328, y: 190))
    arrow.move(to: NSPoint(x: 316, y: 201)); arrow.line(to: NSPoint(x: 328, y: 190)); arrow.line(to: NSPoint(x: 316, y: 179))
    arrow.lineWidth = 2; green.withAlphaComponent(0.65).setStroke(); arrow.stroke()
    NSAttributedString(string: "Drag to Applications · Arraste para Aplicativos", attributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.white.withAlphaComponent(0.5)])
        .draw(at: NSPoint(x: 40, y: 45))
}
try background.write(to: resources.appendingPathComponent("dmg-background.png"))
print("Keynest: ícone e fundo de instalação gerados.")
