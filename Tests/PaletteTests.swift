import AppKit

// The standalone atlas check does not link the interactive character view.
// BodyStyling only needs its shared pink tint; no styling is used in this test.
enum CharacterView {
    static let pink = NSColor(calibratedRed: 1, green: 0.24, blue: 0.57, alpha: 1)
}

@main struct PaletteTests {
    static func check(_ condition: Bool, _ message: String = "Palette check failed") {
        if !condition { print("FAIL: " + message); fflush(stdout); exit(1) }
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
    static func tone(_ pixels: [UInt8]) -> (h: Double, s: Double)? {
        var hues: [Double] = [], saturations: [Double] = []
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let r = Double(pixels[offset]), g = Double(pixels[offset + 1]), b = Double(pixels[offset + 2])
            guard pixels[offset + 3] > 230, b > 235, g > 80, b > g + 30, g > r + 15 else { continue }
            hues.append((4 + (r - g) / (b - r)) / 6)
            saturations.append((b - r) / b)
        }
        guard hues.count > 100 else { return nil }
        hues.sort(); saturations.sort()
        return (hues[hues.count / 2], saturations[saturations.count / 2])
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
    static func sheet(_ frames: [SpriteAtlas.Frame], indices: [Int], columns: Int, directory: URL, name: String,
                      before: [SpriteAtlas.Frame]? = nil) {
        let cellWidth = 225, cellHeight = 220
        let rows = (indices.count + columns - 1) / columns
        let width = cellWidth * columns, height = cellHeight * rows
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!.cgContext
        context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        for (position, index) in indices.enumerated() {
            let col = position % columns, row = position / columns
            let frame = (before != nil && col == 0 ? before! : frames)[index]
            let scale = min(180 / Double(frame.width), 180 / Double(frame.height))
            let rect = NSRect(x: Double(col * cellWidth) + (Double(cellWidth) - Double(frame.width) * scale) / 2,
                y: Double(row * cellHeight + 28), width: Double(frame.width) * scale, height: Double(frame.height) * scale)
            frame.image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            let label = before == nil ? "Pose \(index)" : "\(col == 0 ? "Before" : "After") · pose \(index)"
            (label as NSString).draw(at: NSPoint(x: col * cellWidth + 8, y: row * cellHeight + 5),
                withAttributes: [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.white])
        }
        NSGraphicsContext.restoreGraphicsState()
        try! bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
    }
    static func main() throws {
        setbuf(stdout, nil)
        print("Loading original atlas")
        let original = atlas(false)
        print("Loading corrected atlas")
        let matched = atlas(true)
        print("Comparing all poses")
        check(original.frames.count == 128 && matched.frames.count == 128)
        let reference = tone(rgba(original.frames[0].image))!
        var report: [[String: Any]] = []
        var largestHue = 0.0, largestSaturation = 0.0, correctedHue = 0.0, correctedSaturation = 0.0
        for index in original.frames.indices {
            let before = rgba(original.frames[index].image), after = rgba(matched.frames[index].image)
            check(before.count == after.count && original.frames[index].alpha == matched.frames[index].alpha)
            for offset in stride(from: 0, to: before.count, by: 4) {
                check(before[offset + 3] == after[offset + 3], "Alpha changed at pose \(index)")
                let r = Int(before[offset]), g = Int(before[offset + 1]), b = Int(before[offset + 2])
                if max(r, g, b) * 255 < 135 * Int(before[offset + 3]) || r >= b || g >= b {
                    check(before[offset..<offset + 4].elementsEqual(after[offset..<offset + 4]), "Non-shell detail changed at pose \(index), pixel \(offset / 4): \(Array(before[offset..<offset + 4])) -> \(Array(after[offset..<offset + 4]))")
                }
                let oldValue = max(r, g, b), newValue = after[offset..<offset + 3].max()!
                check(abs(oldValue - Int(newValue)) <= 1, "Lighting changed at pose \(index)")
            }
            if [27, 35, 103].contains(index) {
                check(before == after, "Isolated prop was recoloured")
                continue
            }
            let rawTone = tone(before)!, fixedTone = tone(after)!
            largestHue = max(largestHue, abs(rawTone.h - reference.h))
            largestSaturation = max(largestSaturation, abs(rawTone.s - reference.s))
            check(abs(fixedTone.h - reference.h) < 0.001, "Hue mismatch in pose \(index): \(fixedTone.h), target \(reference.h)")
            correctedHue = max(correctedHue, abs(fixedTone.h - reference.h))
            correctedSaturation = max(correctedSaturation, abs(fixedTone.s - reference.s))
            check(abs(fixedTone.s - reference.s) < 0.003, "Saturation mismatch in pose \(index): \(fixedTone.s), target \(reference.s)")
            report.append(["pose": index, "beforeHue": rawTone.h, "afterHue": fixedTone.h,
                           "beforeSaturation": rawTone.s, "afterSaturation": fixedTone.s])
        }
        check(largestHue > 0.02 && largestSaturation > 0.15, "Fixture no longer reproduces the reported mismatched blue")
        check(rgba(original.frames[0].image) == rgba(matched.frames[0].image), "Standing reference must remain original")
        if CommandLine.arguments.count > 1 {
            let directory = URL(fileURLWithPath: CommandLine.arguments[1])
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: directory.appendingPathComponent("palette.json"))
            for start in stride(from: 0, to: 128, by: 32) {
                sheet(matched.frames, indices: Array(start..<start + 32), columns: 4, directory: directory, name: "palette-\(start).png")
            }
            let poses = [0, 21, 38, 49, 56, 70, 84, 90, 96, 104, 107, 112, 115, 124]
            sheet(matched.frames, indices: poses.flatMap { [$0, $0] }, columns: 2, directory: directory,
                  name: "before-after.png", before: original.frames)
        }
        print("Maximum corrected tone differences: hue \(correctedHue), saturation \(correctedSaturation)")
        print("PASS: all 125 robot poses match one blue reference; alpha, hit regions, brightness, dark visor, mint LEDs, pink details and three isolated props preserved")
    }
}
