import AppKit

// usage: make_icon.swift <outDir>
let outDir = CommandLine.arguments[1]

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    let s = CGFloat(pixels) / 1024.0
    cg.scaleBy(x: s, y: s)
    cg.interpolationQuality = .high

    func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
        CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: a)
    }
    let cs = CGColorSpaceCreateDeviceRGB()

    // macOS icon body: 824pt squircle centered in 1024
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 186, cornerHeight: 186, transform: nil)

    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
    cg.addPath(bodyPath); cg.setFillColor(color(0x0A1A33)); cg.fillPath()
    cg.restoreGState()

    cg.saveGState()
    cg.addPath(bodyPath); cg.clip()

    // night sky -> sea gradient
    let sky = CGGradient(colorsSpace: cs, colors: [color(0x07142B), color(0x0B3B5C), color(0x0F7A86)] as CFArray,
                         locations: [0, 0.55, 1])!
    cg.drawLinearGradient(sky, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

    // sun glow behind island
    let glow = CGGradient(colorsSpace: cs, colors: [color(0xFFD38A, 0.95), color(0xFF9F5A, 0.35), color(0xFF9F5A, 0)] as CFArray,
                          locations: [0, 0.45, 1])!
    cg.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 440), startRadius: 0,
                          endCenter: CGPoint(x: 512, y: 440), endRadius: 330, options: [])
    cg.setFillColor(color(0xFFE3A8))
    cg.fillEllipse(in: CGRect(x: 512 - 120, y: 440 - 120 + 40, width: 240, height: 240))

    // sea (lower band) with lighter horizon
    let seaTop: CGFloat = 400
    let sea = CGGradient(colorsSpace: cs, colors: [color(0x1596A0), color(0x063E58)] as CFArray, locations: [0, 1])!
    cg.saveGState()
    cg.clip(to: CGRect(x: 100, y: 100, width: 824, height: seaTop - 100))
    cg.drawLinearGradient(sea, start: CGPoint(x: 512, y: seaTop), end: CGPoint(x: 512, y: 100), options: [])
    cg.restoreGState()

    // island: sand dome + darker green crown
    let island = CGMutablePath()
    island.move(to: CGPoint(x: 262, y: seaTop - 10))
    island.addCurve(to: CGPoint(x: 512, y: 560), control1: CGPoint(x: 300, y: 500), control2: CGPoint(x: 400, y: 560))
    island.addCurve(to: CGPoint(x: 762, y: seaTop - 10), control1: CGPoint(x: 624, y: 560), control2: CGPoint(x: 724, y: 500))
    island.closeSubpath()
    cg.addPath(island); cg.setFillColor(color(0xF1C77A)); cg.fillPath()

    cg.saveGState()
    cg.addPath(island); cg.clip()
    cg.setFillColor(color(0x2E8B57))
    cg.fillEllipse(in: CGRect(x: 342, y: 488, width: 340, height: 140))
    cg.restoreGState()

    // wave lines
    cg.setStrokeColor(color(0xBFF3F0, 0.55)); cg.setLineWidth(14); cg.setLineCap(.round)
    for (i, y) in [350.0, 285.0, 220.0].enumerated() {
        let inset = CGFloat(i) * 60
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 260 + inset, y: y))
        p.addCurve(to: CGPoint(x: 512, y: y), control1: CGPoint(x: 330 + inset, y: y + 26), control2: CGPoint(x: 430, y: y - 26))
        p.addCurve(to: CGPoint(x: 764 - inset, y: y), control1: CGPoint(x: 594, y: y + 26), control2: CGPoint(x: 694 - inset, y: y - 26))
        cg.addPath(p); cg.strokePath()
    }

    // notch cut-out at the top edge
    let notch = CGMutablePath()
    let nw: CGFloat = 400, nh: CGFloat = 128, r: CGFloat = 64
    let nx = 512 - nw / 2, top: CGFloat = 924
    notch.move(to: CGPoint(x: nx, y: top))
    notch.addLine(to: CGPoint(x: nx, y: top - nh + r))
    notch.addArc(tangent1End: CGPoint(x: nx, y: top - nh), tangent2End: CGPoint(x: nx + r, y: top - nh), radius: r)
    notch.addLine(to: CGPoint(x: nx + nw - r, y: top - nh))
    notch.addArc(tangent1End: CGPoint(x: nx + nw, y: top - nh), tangent2End: CGPoint(x: nx + nw, y: top - nh + r), radius: r)
    notch.addLine(to: CGPoint(x: nx + nw, y: top))
    notch.closeSubpath()
    cg.addPath(notch); cg.setFillColor(color(0x000000)); cg.fillPath()

    cg.restoreGState()
    NSGraphicsContext.current = nil
    return rep.representation(using: .png, properties: [:])!
}

let sizes: [(name: String, px: Int)] = [
    ("icon_16", 16), ("icon_32", 32), ("icon_64", 64), ("icon_128", 128),
    ("icon_256", 256), ("icon_512", 512), ("icon_1024", 1024),
]
for (name, px) in sizes {
    try! render(pixels: px).write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
}
print("ok")
