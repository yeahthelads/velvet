import AppKit

// The standalone atlas check does not link the interactive character view.
// BodyStyling only needs its shared pink tint.
enum CharacterView {
    static let pink = NSColor(calibratedRed: 1, green: 0.24, blue: 0.57, alpha: 1)
}

@main struct AccessoryRenderingTests {
    static var failures = 0
    static func check(_ condition: Bool, _ message: String = "Accessory rendering check failed") {
        if !condition { print("FAIL: " + message); fflush(stdout); failures += 1 }
    }
    static func rgba(_ image: NSImage) -> [UInt8] {
        let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: cg.width, height: cg.height,
                bitsPerComponent: 8, bytesPerRow: cg.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
            context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        }
        return bytes
    }
    static func atlas(_ normalize: Bool) -> SpriteAtlas {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Assets")
        func asset(_ name: String) -> URL { root.appendingPathComponent(name + ".png") }
        return SpriteAtlas(url: asset("velvet-sprites-v5"), additionalURL: asset("vogue-sprites-v2"),
            latteURL: asset("iced-latte-sprites-v2"), interactionURL: asset("interaction-sprites-v2"),
            wellbeingURL: asset("wellbeing-sprites-v1"), discoURL: asset("disco-sprites-v1"),
            clubURL: asset("club-sprites-v1"), stretchURL: asset("stretch-sprites-v1"),
            breakdanceURL: asset("breakdance-sprites-v1"), lifestyleURL: asset("care-sprites-v2"),
            dailyURL: asset("daily-sprites-v1"), yogaURL: asset("yoga-sprites-v2"),
            drawingURL: asset("drawing-sprites-v1"), stylingURL: asset("styling-sprites-v1"),
            normalizeShellColors: normalize)!
    }
    static func main() {
        let sprites = atlas(true)
        var bare: [Int: [UInt8]] = [:]
        func baseline(_ index: Int) -> [UInt8] {
            if let bytes = bare[index] { return bytes }
            let f = sprites.frames[index]
            let image = BodyStyling.render(frame: f, placement: BodyStyling.Placement(navel: nil, hip: nil),
                style: 0, shellUnit: CGFloat(Double(sprites.frames[0].width) * 0.085 / f.unitScale))
            let bytes = rgba(image); bare[index] = bytes; return bytes
        }
        func changes(_ index: Int, _ style: Int) -> [Int] {
            let original = baseline(index), styled = rgba(sprites.image(at: index, style: style))
            return stride(from: 0, to: original.count, by: 4).filter { offset in
                original[offset + 3] > 230 && (0..<3).contains { abs(Int(original[offset + $0]) - Int(styled[offset + $0])) > 20 }
            }.map { $0 / 4 }
        }
        // Same-sized exposed torsos from different sheets and with different
        // arm spans must not stretch the purchased jewellery or tattoo.
        let scalePoses = [0, 9, 64, 67, 124, 125, 126, 127]
        for style in [1, 2, 8] {
            let areas = scalePoses.map { index -> Double in
                let pixels = changes(index, style)
                check(!pixels.isEmpty, "Accessory \(style) missing in exposed pose \(index)")
                return Double(pixels.count) * pow(sprites.frames[index].unitScale, 2)
            }
            print("Physical rendered areas, style \(style): \(areas)")
            check(areas.max()! / areas.min()! < 1.25, "Accessory size varies with pose crop width, style \(style)")
        }
        // An upside-down collar belongs nearer the head than the navel.
        let charm = changes(82, 8), piercing = changes(82, 2), width = sprites.frames[82].width
        let charmY = Double(charm.map { $0 / width }.reduce(0, +)) / Double(charm.count)
        let piercingY = Double(piercing.map { $0 / width }.reduce(0, +)) / Double(piercing.count)
        check(charmY > piercingY + 12, "Upside-down charm is between the feet instead of at the neck")
        for index in [2, 10, 21, 38, 39, 45, 63] {
            check(changes(index, 1).isEmpty, "Tattoo moved onto a covering limb or prop, pose \(index)")
            check(!changes(index, 2).isEmpty, "Visible navel disappeared along with the covered hip, pose \(index)")
        }
        let covered = Array(22...31) + [33, 51, 79, 81, 83] + Array(86...95) + Array(102...106) + Array(108...110) + Array(112...121)
        for index in covered {
            check(sprites.image(at: index, style: 3) === sprites.frames[index].image, "Jewellery/tattoo on a covering prop or limb, pose \(index)")
            check(sprites.image(at: index, style: 8) === sprites.frames[index].image, "Charm floats on a covered torso, pose \(index)")
        }
        // Calibrated raised/crossed legs and all mirror views need visible knit
        // on their blue calves, with both pink soles left untouched.
        for index in [2, 37, 52, 53, 54, 61, 64, 65, 66, 67, 124, 125, 126, 127] {
            let f = sprites.frames[index], original = baseline(index), styled = rgba(sprites.image(at: index, style: 4))
            for leg in LegWarmers.placements(for: index) {
                let x = Int((leg.from.x + leg.to.x) / 2 * CGFloat(f.width))
                let y = Int((leg.from.y + leg.to.y) / 2 * CGFloat(f.height))
                let p = (y * f.width + x) * 4
                check(Int(original[p + 2]) > Int(original[p + 1]) + 10 && Int(original[p + 1]) > Int(original[p]) + 8, "Leg warmer anchor misses blue calf, pose \(index)")
                check(styled[p] > styled[p + 2], "Knit missing on calf, pose \(index)")
            }
        }
        for index in sprites.frames.indices where !LegWarmers.placements(for: index).isEmpty {
            let original = baseline(index), styled = rgba(sprites.image(at: index, style: 4))
            for offset in stride(from: 0, to: original.count, by: 4) {
                let r = Int(original[offset]), g = Int(original[offset + 1]), b = Int(original[offset + 2])
                if original[offset + 3] > 230 && r > b + 20 && r > g + 40 {
                    check(original[offset..<offset + 4].elementsEqual(styled[offset..<offset + 4]), "Leg warmers painted a pink sole, pose \(index)")
                }
            }
        }
        if failures > 0 { exit(1) }
        print("PASS: accessory scale, inverted collar, covered surfaces, both calibrated calves and pink soles")
    }
}
