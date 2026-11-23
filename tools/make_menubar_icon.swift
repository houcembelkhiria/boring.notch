import AppKit

// usage: make_menubar_icon.swift <outDir>
// Draws the DynamicJazira menu bar glyph (island, sun, waves) as a black-on-clear template image.
let outDir = CommandLine.arguments[1]

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    let s = CGFloat(pixels) / 18.0
    cg.scaleBy(x: s, y: s)

    let ink = CGColor(gray: 0, alpha: 1)
    cg.setFillColor(ink)
    cg.setStrokeColor(ink)

    // island dome on the waterline (y = 8)
    let dome = CGMutablePath()
    dome.move(to: CGPoint(x: 2.5, y: 8))
    dome.addCurve(to: CGPoint(x: 9, y: 14), control1: CGPoint(x: 3.5, y: 11.5), control2: CGPoint(x: 6, y: 14))
    dome.addCurve(to: CGPoint(x: 15.5, y: 8), control1: CGPoint(x: 12, y: 14), control2: CGPoint(x: 14.5, y: 11.5))
    dome.closeSubpath()
    cg.addPath(dome); cg.fillPath()

    // waves
    cg.setLineWidth(1.4); cg.setLineCap(.round)
    for (i, y) in [5.6, 3.0].enumerated() {
        let inset = CGFloat(i) * 2.2
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 2.5 + inset, y: y))
        p.addCurve(to: CGPoint(x: 9, y: y), control1: CGPoint(x: 4.2 + inset, y: y + 1.1), control2: CGPoint(x: 7, y: y - 1.1))
        p.addCurve(to: CGPoint(x: 15.5 - inset, y: y), control1: CGPoint(x: 11, y: y + 1.1), control2: CGPoint(x: 13.8 - inset, y: y - 1.1))
        cg.addPath(p); cg.strokePath()
    }

    NSGraphicsContext.current = nil
    return rep.representation(using: .png, properties: [:])!
}

try! render(pixels: 18).write(to: URL(fileURLWithPath: "\(outDir)/menubar.png"))
try! render(pixels: 36).write(to: URL(fileURLWithPath: "\(outDir)/menubar@2x.png"))
try! render(pixels: 54).write(to: URL(fileURLWithPath: "\(outDir)/menubar@3x.png"))
print("ok")
