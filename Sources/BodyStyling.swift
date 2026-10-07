import AppKit

/// Small shell details are baked into a cached pose image, before the existing
/// rotation, crossfade and pixel treatment. Hidden surfaces never wear floating art.
enum BodyStyling {
    struct Placement {
        var navel: NSPoint?
        var hip: NSPoint?
        var size = 1.0
        var angle = 0.0
    }
    /// Torso surface coordinates in each cropped sprite.
    /// Limbs and props can cover either attachment even inside the sprite alpha.
    static func placement(for index: Int) -> Placement? {
        func pose(_ nx: Double, _ ny: Double, _ hx: Double, _ hy: Double,
            size: Double = 1, angle: Double = 0) -> Placement {
            Placement(navel: NSPoint(x: nx, y: ny), hip: NSPoint(x: hx, y: hy), size: size, angle: angle)
        }
        switch index {
        case 0...1, 3, 20, 34, 36, 40, 42...43, 56...57, 68, 84, 96, 99...101, 122...123:
            return pose(0.50, 0.77, 0.60, 0.80)
        case 21: return Placement(navel: NSPoint(x: 0.50, y: 0.77), hip: nil)
        case 2: return Placement(navel: NSPoint(x: 0.45, y: 0.77), hip: nil, angle: 0.08)
        case 5...6: return pose(0.50, 0.75, 0.60, 0.76)
        case 8: return pose(0.50, 0.76, 0.60, 0.79)
        case 9, 44: return pose(0.49, 0.71, 0.58, 0.75)
        case 10: return Placement(navel: NSPoint(x: 0.48, y: 0.70), hip: nil, angle: 0.10)
        case 11: return pose(0.55, 0.73, 0.62, 0.74, angle: -0.12)
        case 12: return pose(0.52, 0.81, 0.58, 0.84, size: 0.85, angle: -0.15)
        case 13: return pose(0.57, 0.79, 0.63, 0.79, size: 0.85, angle: -0.65)
        case 14: return pose(0.56, 0.82, 0.62, 0.81, size: 0.85, angle: -0.55)
        case 15: return Placement(navel: nil, hip: NSPoint(x: 0.61, y: 0.77), size: 0.7, angle: -0.4)
        case 16: return pose(0.49, 0.71, 0.59, 0.72, angle: 0.12)
        case 17: return pose(0.47, 0.71, 0.58, 0.71)
        case 19: return pose(0.56, 0.78, 0.63, 0.78, size: 0.8, angle: -0.65)
        case 32: return Placement(navel: nil, hip: NSPoint(x: 0.61, y: 0.78))
        case 37: return pose(0.48, 0.76, 0.37, 0.80)
        case 38...39: return Placement(navel: NSPoint(x: 0.50, y: 0.82), hip: nil, size: 0.75)
        case 41: return pose(0.50, 0.80, 0.62, 0.80, size: 0.8)
        case 45: return Placement(navel: NSPoint(x: 0.44, y: 0.75), hip: nil, angle: 0.18)
        case 48: return pose(0.54, 0.73, 0.62, 0.75, angle: -0.3)
        case 52: return pose(0.50, 0.77, 0.61, 0.79)
        case 53: return pose(0.49, 0.73, 0.59, 0.77, angle: 0.1)
        case 54: return pose(0.56, 0.75, 0.63, 0.78, angle: -0.25)
        case 55: return pose(0.46, 0.71, 0.54, 0.73)
        case 58...59: return pose(0.49, 0.73, 0.60, 0.72)
        case 60: return pose(0.47, 0.76, 0.58, 0.79)
        case 61: return pose(0.47, 0.72, 0.58, 0.71, angle: 0.12)
        case 62: return pose(0.51, 0.72, 0.61, 0.74, angle: -0.12)
        case 63: return Placement(navel: NSPoint(x: 0.48, y: 0.71), hip: nil)
        case 64: return pose(0.47, 0.72, 0.57, 0.73)
        case 65: return pose(0.49, 0.70, 0.59, 0.71, size: 0.9)
        case 66: return pose(0.48, 0.67, 0.58, 0.70, size: 0.9)
        case 67: return pose(0.49, 0.71, 0.60, 0.72, angle: -0.15)
        case 76...77: return pose(0.48, 0.70, 0.58, 0.70)
        case 78: return pose(0.53, 0.72, 0.61, 0.71, size: 0.85, angle: -0.7)
        case 80: return pose(0.48, 0.75, 0.57, 0.77, size: 0.85, angle: 0.3)
        case 82: return pose(0.50, 0.28, 0.59, 0.29, size: 0.85, angle: .pi)
        case 85: return pose(0.37, 0.78, 0.45, 0.78, size: 0.8, angle: 0.10)
        case 107, 111: return pose(0.49, 0.78, 0.61, 0.79, size: 0.85)
        case 124: return pose(0.46, 0.77, 0.56, 0.80)
        case 125: return pose(0.37, 0.77, 0.48, 0.80, angle: 0.08)
        case 126: return pose(0.43, 0.78, 0.54, 0.81, angle: -0.08)
        case 127: return pose(0.41, 0.77, 0.52, 0.80)
        default: return nil
        }
    }

    static func render(frame: SpriteAtlas.Frame, placement: Placement, style: Int, legs: [LegWarmers.Leg] = [], showsCharm: Bool = true,
        shellUnit: CGFloat) -> NSImage {
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: frame.width, pixelsHigh: frame.height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
            let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else { return frame.image }
        NSGraphicsContext.saveGraphicsState()
        let ctx = graphics.cgContext
        ctx.translateBy(x: 0, y: CGFloat(frame.height)); ctx.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        let rect = NSRect(x: 0, y: 0, width: frame.width, height: frame.height)
        frame.image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        // Preserve source alpha: decorations cannot extend the sprite hitbox.
        let unit = shellUnit * placement.size
        func shell(_ point: NSPoint) -> Bool {
            frame.contains(x: Double(point.x * rect.width), y: Double(point.y * rect.height))
        }
        if style & 8 != 0, showsCharm, let navel = placement.navel {
            // Move toward the neck along the torso axis, including upside-down
            // poses. A fixed y offset put the charm between her feet in freezes.
            let chest = NSPoint(x: navel.x + sin(placement.angle) * unit * 0.95 / rect.width,
                y: navel.y - cos(placement.angle) * unit * 0.95 / rect.height)
            if shell(chest) {
                ctx.saveGState(); ctx.translateBy(x: chest.x * rect.width, y: chest.y * rect.height)
                ctx.rotate(by: placement.angle); ctx.scaleBy(x: unit, y: unit)
                drawHeartCharm(); ctx.restoreGState()
            }
        }
        if style & 1 != 0, let hip = placement.hip, shell(hip) {
            ctx.saveGState(); ctx.translateBy(x: hip.x * rect.width, y: hip.y * rect.height)
            ctx.rotate(by: placement.angle); ctx.scaleBy(x: shellUnit * placement.size * 0.85, y: shellUnit * placement.size * 0.85)
            drawTribalHeart(); ctx.restoreGState()
        }
        if style & 2 != 0, let navel = placement.navel, shell(navel) {
            ctx.saveGState(); ctx.translateBy(x: navel.x * rect.width, y: navel.y * rect.height)
            // A constant body-relative scale prevents wide arms/props enlarging
            // the jewellery. Rotate about its centre, not its upper bead.
            ctx.rotate(by: placement.angle); ctx.scaleBy(x: shellUnit * placement.size * 1.9, y: shellUnit * placement.size * 1.9)
            ctx.translateBy(x: 0, y: -0.195)
            drawPiercing(); ctx.restoreGState()
        }
        if style & 4 != 0, let pixels = bitmap.bitmapData {
            let original = Array(UnsafeBufferPointer(start: pixels, count: bitmap.bytesPerRow * frame.height))
            LegWarmers.draw(legs, in: rect, referenceWidth: shellUnit / 0.085)
            // Knit wraps the blue calf. Forward-facing soles and covering props
            // remain untouched even in foreshortened or folded poses.
            let first = bitmap.bitmapFormat.contains(.alphaFirst) ? 1 : 0
            for y in 0..<frame.height {
                for x in 0..<frame.width {
                    let offset = y * bitmap.bytesPerRow + x * 4
                    let r = Int(original[offset + first]), g = Int(original[offset + first + 1]), b = Int(original[offset + first + 2])
                    if !(b > g + 10 && g > r + 8) {
                        for channel in 0..<4 { pixels[offset + channel] = original[offset + channel] }
                    }
                }
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        // Restore the silhouette alpha after drawing; ink and jewelry cannot
        // create opaque pixels outside the source shell or change hit testing.
        if let bytes = bitmap.bitmapData {
            let alphaChannel = bitmap.bitmapFormat.contains(.alphaFirst) ? 0 : 3
            let premultiplied = !bitmap.bitmapFormat.contains(.alphaNonpremultiplied)
            for y in 0..<frame.height {
                for x in 0..<frame.width {
                    let offset = y * bitmap.bytesPerRow + x * 4
                    let original = frame.alpha[y * frame.width + x]
                    let drawn = bytes[offset + alphaChannel]
                    if drawn != original {
                        for channel in 0..<4 where channel != alphaChannel {
                            if original == 0 { bytes[offset + channel] = 0 }
                            else if premultiplied && drawn > 0 {
                                bytes[offset + channel] = UInt8(min(255, Int(bytes[offset + channel]) * Int(original) / Int(drawn)))
                            }
                        }
                        bytes[offset + alphaChannel] = original
                    }
                }
            }
        }
        return NSImage(cgImage: bitmap.cgImage!, size: rect.size)
    }
    private static func drawHeartCharm() {
        let chain = NSBezierPath(); chain.move(to: NSPoint(x: -1.25, y: -0.52))
        chain.curve(to: NSPoint(x: 1.25, y: -0.52), controlPoint1: NSPoint(x: -0.48, y: 0.03), controlPoint2: NSPoint(x: 0.48, y: 0.03))
        NSColor(calibratedWhite: 0.32, alpha: 0.5).setStroke(); chain.lineWidth = 0.042; chain.stroke()
        NSColor(calibratedWhite: 0.89, alpha: 1).setStroke(); chain.lineWidth = 0.023; chain.stroke()
        let heart = NSBezierPath(); heart.move(to: NSPoint(x: 0, y: -0.10))
        heart.curve(to: NSPoint(x: -0.29, y: -0.03), controlPoint1: NSPoint(x: -0.14, y: -0.34), controlPoint2: NSPoint(x: -0.38, y: -0.24))
        heart.curve(to: NSPoint(x: 0, y: 0.29), controlPoint1: NSPoint(x: -0.28, y: 0.12), controlPoint2: NSPoint(x: -0.12, y: 0.18))
        heart.curve(to: NSPoint(x: 0.29, y: -0.03), controlPoint1: NSPoint(x: 0.12, y: 0.18), controlPoint2: NSPoint(x: 0.28, y: 0.12))
        heart.curve(to: NSPoint(x: 0, y: -0.10), controlPoint1: NSPoint(x: 0.38, y: -0.24), controlPoint2: NSPoint(x: 0.14, y: -0.34))
        heart.close()
        NSGradient(colors: [.white, NSColor(calibratedWhite: 0.88, alpha: 1), NSColor(calibratedWhite: 0.40, alpha: 1)])?.draw(in: heart, angle: 65)
        NSColor(calibratedWhite: 0.25, alpha: 0.5).setStroke(); heart.lineWidth = 0.027; heart.stroke()
        NSColor.white.withAlphaComponent(0.9).setFill()
        NSBezierPath(ovalIn: NSRect(x: -0.19, y: -0.12, width: 0.13, height: 0.06)).fill()
    }
    private static func drawTribalHeart() {
        let heart = NSBezierPath()
        heart.move(to: NSPoint(x: 0, y: -0.25))
        heart.curve(to: NSPoint(x: -0.40, y: -0.08), controlPoint1: NSPoint(x: -0.22, y: -0.63), controlPoint2: NSPoint(x: -0.59, y: -0.33))
        heart.curve(to: NSPoint(x: 0.10, y: 0.51), controlPoint1: NSPoint(x: -0.44, y: 0.22), controlPoint2: NSPoint(x: -0.05, y: 0.29))
        heart.curve(to: NSPoint(x: 0.40, y: -0.10), controlPoint1: NSPoint(x: 0.13, y: 0.22), controlPoint2: NSPoint(x: 0.55, y: 0.08))
        heart.curve(to: NSPoint(x: 0, y: -0.25), controlPoint1: NSPoint(x: 0.49, y: -0.41), controlPoint2: NSPoint(x: 0.12, y: -0.50))
        heart.close()
        let inside = NSBezierPath()
        inside.move(to: NSPoint(x: 0, y: -0.13))
        inside.curve(to: NSPoint(x: -0.25, y: -0.05), controlPoint1: NSPoint(x: -0.18, y: -0.37), controlPoint2: NSPoint(x: -0.33, y: -0.24))
        inside.curve(to: NSPoint(x: 0.03, y: 0.25), controlPoint1: NSPoint(x: -0.29, y: 0.10), controlPoint2: NSPoint(x: -0.03, y: 0.21))
        inside.curve(to: NSPoint(x: 0.25, y: -0.06), controlPoint1: NSPoint(x: 0.06, y: 0.11), controlPoint2: NSPoint(x: 0.34, y: 0.04))
        inside.curve(to: NSPoint(x: 0, y: -0.13), controlPoint1: NSPoint(x: 0.31, y: -0.28), controlPoint2: NSPoint(x: 0.12, y: -0.37))
        inside.close(); heart.append(inside); heart.windingRule = .evenOdd
        NSColor(calibratedRed: 0.045, green: 0.055, blue: 0.09, alpha: 0.93).setFill(); heart.fill()
        let spikes = NSBezierPath()
        for points in [[NSPoint(x: -0.29, y: -0.27), NSPoint(x: -0.42, y: -0.58), NSPoint(x: -0.05, y: -0.25)],
                       [NSPoint(x: 0.22, y: -0.31), NSPoint(x: 0.44, y: -0.54), NSPoint(x: 0.37, y: -0.01)],
                       [NSPoint(x: -0.40, y: 0.02), NSPoint(x: -0.64, y: -0.10), NSPoint(x: -0.28, y: 0.21)],
                       [NSPoint(x: 0.29, y: 0.11), NSPoint(x: 0.36, y: 0.68), NSPoint(x: 0.09, y: 0.25)]] {
            spikes.move(to: points[0]); spikes.line(to: points[1]); spikes.line(to: points[2]); spikes.close()
        }
        spikes.fill()
    }
    private static func drawPiercing() {
        NSColor.black.withAlphaComponent(0.20).setFill()
        NSBezierPath(ovalIn: NSRect(x: -0.07, y: -0.10, width: 0.19, height: 0.57)).fill()
        let bar = NSBezierPath(); bar.move(to: NSPoint(x: 0, y: -0.02))
        bar.curve(to: NSPoint(x: 0, y: 0.32), controlPoint1: NSPoint(x: 0.04, y: 0.08), controlPoint2: NSPoint(x: 0.04, y: 0.24))
        NSColor(calibratedWhite: 0.53, alpha: 1).setStroke(); bar.lineWidth = 0.048; bar.stroke()
        NSColor(calibratedWhite: 0.94, alpha: 1).setStroke(); bar.lineWidth = 0.022; bar.stroke()
        func bead(_ rect: NSRect) {
            let path = NSBezierPath(ovalIn: rect)
            NSGradient(colors: [.white, NSColor(calibratedWhite: 0.82, alpha: 1), NSColor(calibratedWhite: 0.30, alpha: 1)])?.draw(in: path, angle: 65)
        }
        bead(NSRect(x: -0.07, y: -0.11, width: 0.14, height: 0.14))
        bead(NSRect(x: -0.11, y: 0.28, width: 0.22, height: 0.22))
        let stone = NSBezierPath(ovalIn: NSRect(x: -0.075, y: 0.305, width: 0.15, height: 0.15))
        NSGradient(colors: [NSColor(calibratedRed: 1, green: 0.84, blue: 0.91, alpha: 1), CharacterView.pink.withAlphaComponent(0.9)])?.draw(in: stone, angle: 65)
        NSColor.white.withAlphaComponent(0.9).setFill()
        NSBezierPath(ovalIn: NSRect(x: -0.049, y: 0.32, width: 0.035, height: 0.035)).fill()
    }
}
