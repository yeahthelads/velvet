import AppKit

/// Knit follows the lower legs, leaving the pink soles visible. Covered calves
/// have no placement; props and the visor never receive clothing.
enum LegWarmers {
    struct Leg {
        let from: NSPoint
        let to: NSPoint
        let width: CGFloat
    }
    static func placements(for index: Int) -> [Leg] {
        func leg(_ x: CGFloat, _ y: CGFloat, _ endX: CGFloat, _ endY: CGFloat, _ width: CGFloat = 0.15) -> Leg {
            Leg(from: NSPoint(x: x, y: y), to: NSPoint(x: endX, y: endY), width: width)
        }
        let standing = [leg(0.41, 0.87, 0.41, 0.95, 0.17), leg(0.60, 0.87, 0.60, 0.95, 0.17)]
        switch index {
        case 0...1, 3, 7, 20...26, 28...31, 33, 36, 38...43, 56...57, 68, 84, 86...88, 93...96, 99...102, 120...123:
            return standing
        case 2: return [leg(0.34, 0.87, 0.34, 0.95, 0.17), leg(0.56, 0.87, 0.56, 0.95, 0.17)]
        case 37: return [leg(0.36, 0.87, 0.36, 0.95, 0.17), leg(0.53, 0.87, 0.53, 0.95, 0.17)]
        case 4: return [leg(0.38, 0.77, 0.29, 0.80), leg(0.50, 0.84, 0.46, 0.87)]
        case 5...6: return [leg(0.45, 0.87, 0.39, 0.91), leg(0.55, 0.86, 0.59, 0.90)]
        case 8: return [leg(0.40, 0.86, 0.39, 0.93), leg(0.59, 0.86, 0.58, 0.94)]
        case 9, 44: return [leg(0.47, 0.88, 0.45, 0.92, 0.12)]
        case 10: return [leg(0.40, 0.86, 0.40, 0.94, 0.12), leg(0.60, 0.80, 0.61, 0.82, 0.12)]
        case 11: return [leg(0.58, 0.87, 0.58, 0.95, 0.12), leg(0.26, 0.74, 0.19, 0.74, 0.12)]
        case 12: return [leg(0.62, 0.86, 0.63, 0.93, 0.13), leg(0.75, 0.86, 0.79, 0.93, 0.13)]
        case 13: return [leg(0.82, 0.86, 0.88, 0.86, 0.12)]
        case 14: return [leg(0.77, 0.72, 0.82, 0.68, 0.11), leg(0.74, 0.89, 0.76, 0.90, 0.11)]
        case 15: return [leg(0.60, 0.91, 0.66, 0.92, 0.13)]
        case 16: return [leg(0.48, 0.86, 0.47, 0.94), leg(0.61, 0.87, 0.64, 0.94)]
        case 17: return [leg(0.49, 0.87, 0.44, 0.94, 0.12)]
        case 18: return [leg(0.52, 0.87, 0.49, 0.91, 0.12), leg(0.61, 0.87, 0.67, 0.91, 0.12)]
        case 19: return [leg(0.83, 0.86, 0.90, 0.86, 0.12)]
        case 32, 34: return [leg(0.40, 0.87, 0.40, 0.94), leg(0.55, 0.87, 0.59, 0.91)]
        case 45: return [leg(0.52, 0.86, 0.52, 0.94), leg(0.64, 0.86, 0.66, 0.94)]
        case 46...47, 97: return [leg(0.43, 0.80, 0.39, 0.81, 0.12), leg(0.58, 0.84, 0.56, 0.85, 0.12)]
        case 48: return [leg(0.43, 0.86, 0.41, 0.95, 0.12), leg(0.69, 0.81, 0.78, 0.84, 0.12)]
        case 49...50: return [leg(0.81, 0.87, 0.87, 0.87, 0.10)]
        case 51: return [leg(0.62, 0.86, 0.62, 0.88, 0.14), leg(0.76, 0.86, 0.76, 0.88, 0.14)]
        case 52: return [leg(0.36, 0.87, 0.32, 0.94, 0.17), leg(0.66, 0.87, 0.68, 0.94, 0.17)]
        case 53: return [leg(0.37, 0.87, 0.37, 0.95, 0.17), leg(0.59, 0.87, 0.64, 0.94, 0.17)]
        case 54: return [leg(0.44, 0.86, 0.42, 0.94, 0.17), leg(0.77, 0.86, 0.75, 0.94, 0.17)]
        case 55: return [leg(0.37, 0.88, 0.31, 0.91, 0.12), leg(0.42, 0.87, 0.48, 0.93, 0.12)]
        case 58...59: return [leg(0.42, 0.85, 0.37, 0.90, 0.13), leg(0.53, 0.84, 0.59, 0.90, 0.14)]
        case 65: return [leg(0.33, 0.83, 0.28, 0.86, 0.12), leg(0.49, 0.86, 0.55, 0.94, 0.16)]
        case 66: return [leg(0.39, 0.84, 0.34, 0.88, 0.12), leg(0.52, 0.83, 0.59, 0.89, 0.15)]
        case 60: return [leg(0.30, 0.87, 0.22, 0.91, 0.13), leg(0.64, 0.87, 0.71, 0.91, 0.13)]
        case 61: return [leg(0.35, 0.82, 0.31, 0.87, 0.12), leg(0.51, 0.82, 0.56, 0.85, 0.14)]
        case 62: return [leg(0.47, 0.85, 0.49, 0.93, 0.12), leg(0.56, 0.86, 0.61, 0.92, 0.12)]
        case 63: return [leg(0.43, 0.84, 0.44, 0.94, 0.12), leg(0.67, 0.77, 0.70, 0.79, 0.12)]
        case 64: return [leg(0.28, 0.86, 0.23, 0.94, 0.17), leg(0.70, 0.86, 0.73, 0.94, 0.17)]
        case 67: return [leg(0.34, 0.86, 0.35, 0.94, 0.17), leg(0.70, 0.86, 0.69, 0.94, 0.17)]
        case 69...70, 72...75: return [leg(0.23, 0.87, 0.17, 0.87, 0.10), leg(0.77, 0.87, 0.83, 0.87, 0.10)]
        case 71: return [leg(0.19, 0.83, 0.10, 0.83, 0.10), leg(0.80, 0.85, 0.91, 0.85, 0.10)]
        case 76...77: return [leg(0.49, 0.86, 0.47, 0.95, 0.12)]
        case 78: return [leg(0.79, 0.78, 0.86, 0.81, 0.11)]
        case 79: return [leg(0.77, 0.62, 0.80, 0.67, 0.11)]
        case 80: return [leg(0.20, 0.81, 0.17, 0.85, 0.12)]
        case 81: return [leg(0.87, 0.55, 0.92, 0.56, 0.11), leg(0.83, 0.75, 0.88, 0.75, 0.11)]
        case 82: return [leg(0.31, 0.18, 0.27, 0.12, 0.13), leg(0.66, 0.18, 0.70, 0.13, 0.13)]
        case 83: return [leg(0.85, 0.61, 0.91, 0.61, 0.11), leg(0.74, 0.79, 0.77, 0.81, 0.11)]
        case 85: return [leg(0.27, 0.84, 0.25, 0.86, 0.10), leg(0.38, 0.88, 0.38, 0.90, 0.10)]
        case 89...91, 98, 104...107, 111, 116...119:
            return [leg(0.32, 0.85, 0.28, 0.87, 0.12), leg(0.64, 0.87, 0.68, 0.89, 0.12)]
        case 92: return [leg(0.37, 0.86, 0.37, 0.95, 0.13), leg(0.55, 0.86, 0.54, 0.95, 0.13)]
        case 108...109, 113, 115: return [leg(0.80, 0.81, 0.85, 0.81, 0.10)]
        case 110, 114: return [leg(0.73, 0.87, 0.77, 0.87, 0.11)]
        case 112: return [leg(0.79, 0.84, 0.82, 0.86, 0.11)]
        case 124: return [leg(0.37, 0.87, 0.37, 0.95, 0.12), leg(0.54, 0.87, 0.54, 0.95, 0.12)]
        case 125: return [leg(0.29, 0.87, 0.29, 0.95, 0.17), leg(0.48, 0.87, 0.48, 0.95, 0.17)]
        case 126: return [leg(0.33, 0.87, 0.33, 0.95, 0.17), leg(0.52, 0.87, 0.52, 0.95, 0.17)]
        case 127: return [leg(0.35, 0.87, 0.35, 0.95, 0.17), leg(0.55, 0.87, 0.55, 0.95, 0.17)]
        default: return [] // isolated coffee cup, paper and chocolate bar
        }
    }

    static func draw(_ legs: [Leg], in bounds: NSRect, referenceWidth: CGFloat) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        for leg in legs {
            let start = NSPoint(x: leg.from.x * bounds.width, y: leg.from.y * bounds.height)
            let end = NSPoint(x: leg.to.x * bounds.width, y: leg.to.y * bounds.height)
            let dx = end.x - start.x, dy = end.y - start.y
            // Spread limbs and nearby props widen the crop, not the calf.
            let width = leg.width * referenceWidth
            let length = max(width * 0.35, hypot(dx, dy))
            context.saveGState()
            context.translateBy(x: start.x, y: start.y)
            context.rotate(by: atan2(dy, dx) - .pi / 2)
            let cloth = NSBezierPath(roundedRect: NSRect(x: -width / 2, y: 0, width: width, height: length),
                xRadius: width * 0.13, yRadius: width * 0.13)
            NSGradient(colors: [NSColor(calibratedRed: 0.75, green: 0.41, blue: 0.57, alpha: 1),
                NSColor(calibratedRed: 1, green: 0.78, blue: 0.85, alpha: 1),
                NSColor(calibratedRed: 0.82, green: 0.51, blue: 0.65, alpha: 1)])?.draw(in: cloth, angle: 0)
            context.saveGState(); cloth.addClip()
            // Fine vertical knit ribs with soft shade, rather than painted stripes.
            for x in stride(from: -width / 2, through: width / 2, by: max(1, width / 12)) {
                let rib = NSBezierPath(); rib.move(to: NSPoint(x: x, y: 0)); rib.line(to: NSPoint(x: x, y: length))
                NSColor(calibratedRed: 0.68, green: 0.34, blue: 0.47, alpha: 0.22).setStroke()
                rib.lineWidth = max(0.5, width * 0.015); rib.stroke()
            }
            for y in [length * 0.10, length * 0.22, length * 0.75, length * 0.88] {
                let fold = NSBezierPath(); fold.move(to: NSPoint(x: -width / 2, y: y))
                fold.curve(to: NSPoint(x: width / 2, y: y), controlPoint1: NSPoint(x: -width / 4, y: y + 1),
                    controlPoint2: NSPoint(x: width / 4, y: y + 1))
                NSColor.white.withAlphaComponent(0.28).setStroke(); fold.lineWidth = max(0.8, width * 0.025); fold.stroke()
            }
            context.restoreGState(); context.restoreGState()
        }
    }
}
