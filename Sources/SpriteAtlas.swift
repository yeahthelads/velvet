import AppKit

/// Loads the artist's uniform atlas into animation cells. Tiny disconnected alpha
/// specks outside the main silhouette are ignored when finding cell bounds.
final class SpriteAtlas {
    struct Frame {
        var image: NSImage
        let width: Int
        let height: Int
        let alpha: [UInt8]
        let cropLeft: Int
        let cropTop: Int
        let cellWidth: Int
        var unitScale = 1.0
        var anchorX: Double?
        var footGap = 0.0
        func contains(x: Double, y: Double) -> Bool {
            let px = Int(x), py = Int(y)
            guard px >= 0, py >= 0, px < width, py < height else { return false }
            return alpha[py * width + px] > 45
        }
    }
    let frames: [Frame]
    let scale: Double
    let cellWidth: Double

    init?(url: URL, columns: Int = 4, rows: Int = 4, rowFractions: [Double]? = nil, primarySilhouetteOnly: Bool = false, additionalURL: URL? = nil, latteURL: URL? = nil, interactionURL: URL? = nil, wellbeingURL: URL? = nil, discoURL: URL? = nil, clubURL: URL? = nil, stretchURL: URL? = nil, breakdanceURL: URL? = nil, lifestyleURL: URL? = nil, dailyURL: URL? = nil, yogaURL: URL? = nil, drawingURL: URL? = nil) {
        guard let source = NSImage(contentsOf: url)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let edges = rowFractions ?? (0...rows).map { Double($0) / Double(rows) }
        guard edges.count == rows + 1, edges.first == 0, edges.last == 1 else { return nil }
        var output: [Frame] = []
        for row in 0..<rows {
            for column in 0..<columns {
                let x = column * source.width / columns, y = Int((edges[row] * Double(source.height)).rounded())
                let width = (column + 1) * source.width / columns - x
                let height = Int((edges[row + 1] * Double(source.height)).rounded()) - y
                guard height > 0 else { return nil }
                guard let cell = source.cropping(to: CGRect(x: x, y: y, width: width, height: height)) else { return nil }
                let alpha = Self.alphaBytes(cell)
                let box = Self.silhouetteBounds(alpha, width: width, height: height, primaryOnly: primarySilhouetteOnly)
                guard let cropped = cell.cropping(to: box) else { return nil }
                output.append(Frame(image: NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height)), width: cropped.width, height: cropped.height, alpha: Self.alphaBytes(cropped), cropLeft: Int(box.minX), cropTop: Int(box.minY), cellWidth: width))
            }
        }
        guard output.count == columns * rows else { return nil }
        cellWidth = Double(source.width) / Double(columns)
        if let additionalURL, let extra = SpriteAtlas(url: additionalURL, columns: 2, rows: 2) {
            let sizeRatio = cellWidth / extra.cellWidth
            output.append(contentsOf: extra.frames.map {
                var frame = $0
                frame.unitScale *= sizeRatio
                return frame
            })
        }
        if let latteURL, let extra = SpriteAtlas(url: latteURL, columns: 4, rows: 2) {
            // Match the standing robot's height rather than the atlas padding.
            // The isolated cup has its own display size.
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            output.append(contentsOf: extra.frames.enumerated().map { index, sourceFrame in
                var frame = sourceFrame
                frame.unitScale *= sizeRatio
                if index < 7 {
                    frame.anchorX = Double(frame.cropLeft) - Double(frame.cellWidth) / 2
                }
                return frame
            })
        }
        // This sheet has slightly uneven transparent gutters between its rows.
        if let interactionURL, let extra = SpriteAtlas(url: interactionURL, rowFractions: [0, 355.0 / 1254, 660.0 / 1254, 950.0 / 1254, 1]) {
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            let center = Double(extra.frames[0].cropLeft) + Double(extra.frames[0].width) / 2
            output.append(contentsOf: extra.frames.map {
                var frame = $0
                frame.unitScale *= sizeRatio
                frame.anchorX = Double(frame.cropLeft) - center
                return frame
            })
        }
        scale = min(172 / Double(output[0].height), 180 / output.map { Double($0.width) * $0.unitScale }.max()!, 180 / output.map { Double($0.height) * $0.unitScale }.max()!)
        if let wellbeingURL, let extra = SpriteAtlas(url: wellbeingURL, columns: 4, rows: 2, rowFractions: [0, 478.0 / 887, 1]) {
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            output.append(contentsOf: extra.frames.map {
                var frame = $0
                frame.unitScale *= sizeRatio
                return frame
            })
        }
        if let discoURL, let extra = SpriteAtlas(url: discoURL, columns: 2, rows: 2) {
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            output.append(contentsOf: extra.frames.map {
                var frame = $0; frame.unitScale *= sizeRatio
                return frame
            })
        }
        if let clubURL, let extra = SpriteAtlas(url: clubURL, columns: 4, rows: 3, rowFractions: [0, 362.0 / 1086, 709.0 / 1086, 1]) {
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            output.append(contentsOf: extra.frames.map {
                var frame = $0; frame.unitScale *= sizeRatio
                return frame
            })
        }
        if let stretchURL, let extra = SpriteAtlas(url: stretchURL, columns: 4, rows: 2, rowFractions: [0, 475.0 / 887, 1]) {
            // The first cell is standing so seated/low poses retain her head size.
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            output.append(contentsOf: extra.frames.map {
                var frame = $0; frame.unitScale *= sizeRatio
                return frame
            })
        }
        if let breakdanceURL, let extra = SpriteAtlas(url: breakdanceURL, columns: 4, rows: 2, rowFractions: [0, 461.0 / 887, 1]) {
            // Standing toprock calibrates the sheet so floorwork keeps her head size.
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            output.append(contentsOf: extra.frames.map {
                var frame = $0; frame.unitScale *= sizeRatio
                return frame
            })
        }
        if let lifestyleURL, let extra = SpriteAtlas(url: lifestyleURL, columns: 4, rows: 4) {
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            output.append(contentsOf: extra.frames.map {
                var frame = $0; frame.unitScale *= sizeRatio
                return frame
            })
        }
        if let dailyURL, let extra = SpriteAtlas(url: dailyURL, columns: 4, rows: 4, rowFractions: [0, 350.0 / 1280, 675.0 / 1280, 945.0 / 1280, 1]) {
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            output.append(contentsOf: extra.frames.map {
                var frame = $0; frame.unitScale *= sizeRatio; return frame
            })
        }
        // Only the four yoga cells change; all food, laptop and sleep art stays original.
        if let yogaURL, output.count >= 116, let extra = SpriteAtlas(url: yogaURL, rowFractions: [0, 350.0 / 1280, 675.0 / 1280, 945.0 / 1280, 1], primarySilhouetteOnly: true) {
            let sizeRatio = Double(output[0].height) / Double(extra.frames[0].height)
            for index in 0..<4 {
                var frame = extra.frames[12 + index]; frame.unitScale *= sizeRatio
                output[112 + index] = frame
            }
        }
        if let drawingURL, output.count == 116, let extra = SpriteAtlas(url: drawingURL, columns: 4, rows: 2) {
            let sizeRatio = Double(output[0].height) / Double(extra.frames[4].height)
            let center = Double(extra.frames[4].cropLeft) + Double(extra.frames[4].width) / 2
            output.append(contentsOf: extra.frames.map {
                var frame = $0; frame.unitScale *= sizeRatio
                frame.anchorX = Double(frame.cropLeft) - center
                return frame
            })
        }
        // Sleep artwork comes from separately generated sheets with a more
        // saturated cyan-blue shell. Match only its shell hue/saturation to
        // the standing reference once at load time, preserving light and props.
        for index in [44, 45, 46, 47, 96, 97, 107, 108, 109, 110, 111] + Array(116..<124) where index < output.count {
            output[index].image = Self.matchingShellBlue(output[index].image, reference: output[0].image)
        }
        frames = output
    }

    private static func rgbaBytes(_ image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        pixels.withUnsafeMutableBytes { buffer in
            let info = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            guard let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info) else { return }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return pixels
    }
    private static func alphaBytes(_ image: CGImage) -> [UInt8] {
        let pixels = rgbaBytes(image)
        return (0..<(image.width * image.height)).map { pixels[$0 * 4 + 3] }
    }
    private static func shellTone(_ pixels: [UInt8]) -> (hue: CGFloat, saturation: CGFloat)? {
        var hues: [CGFloat] = [], saturations: [CGFloat] = []
        for offset in stride(from: 0, to: pixels.count, by: 4) where pixels[offset + 3] > 230 {
            let r = Int(pixels[offset]), g = Int(pixels[offset + 1]), b = Int(pixels[offset + 2])
            guard r > 35, g > 80, b > g + 30, g > r + 15 else { continue }
            let range = CGFloat(b - r)
            hues.append((CGFloat(r - g) / range + 4) / 6)
            saturations.append(range / CGFloat(b))
        }
        guard hues.count > 100 else { return nil }
        hues.sort(); saturations.sort()
        return (hues[hues.count / 2], saturations[saturations.count / 2])
    }
    private static func matchingShellBlue(_ image: NSImage, reference: NSImage) -> NSImage {
        guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let target = reference.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return image }
        var pixels = rgbaBytes(source)
        guard let from = shellTone(pixels), let to = shellTone(rgbaBytes(target)) else { return image }
        let hueShift = to.hue - from.hue, saturationScale = to.saturation / from.saturation
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = CGFloat(pixels[offset + 3]) / 255
            guard alpha > 0 else { continue }
            let r = min(1, CGFloat(pixels[offset]) / 255 / alpha)
            let g = min(1, CGFloat(pixels[offset + 1]) / 255 / alpha)
            let b = min(1, CGFloat(pixels[offset + 2]) / 255 / alpha)
            // Leave the dark visor, mint face, piercing, shoes and props alone.
            guard b > g + 0.10, g > r + 0.06, g > 0.20 else { continue }
            let range = b - r
            let hue = min(1, max(0, ((r - g) / range + 4) / 6 + hueShift)) * 6
            let saturation = min(1, range / b * saturationScale)
            let sector = Int(hue), fraction = hue - CGFloat(sector)
            let p = b * (1 - saturation), q = b * (1 - fraction * saturation), t = b * (1 - (1 - fraction) * saturation)
            let channels: [CGFloat]
            switch sector % 6 {
            case 0: channels = [b, t, p]
            case 1: channels = [q, b, p]
            case 2: channels = [p, b, t]
            case 3: channels = [p, q, b]
            case 4: channels = [t, p, b]
            default: channels = [b, p, q]
            }
            for channel in 0..<3 {
                pixels[offset + channel] = UInt8(min(255, max(0, (channels[channel] * alpha * 255).rounded())))
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let result = CGImage(width: source.width, height: source.height, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: source.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
                provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return image }
        return NSImage(cgImage: result, size: image.size)
    }

    private static func silhouetteBounds(_ alpha: [UInt8], width: Int, height: Int, primaryOnly: Bool) -> CGRect {
        struct Component { var count: Int; var left: Int; var top: Int; var right: Int; var bottom: Int }
        var seen = [Bool](repeating: false, count: alpha.count)
        var components: [Component] = []
        for start in alpha.indices where !seen[start] && alpha[start] > 45 {
            var queue = [start], cursor = 0
            seen[start] = true
            var component = Component(count: 0, left: width, top: height, right: 0, bottom: 0)
            while cursor < queue.count {
                let index = queue[cursor]; cursor += 1
                let x = index % width, y = index / width
                component.count += 1
                component.left = min(component.left, x); component.right = max(component.right, x)
                component.top = min(component.top, y); component.bottom = max(component.bottom, y)
                var neighbors: [Int] = []
                if x > 0 { neighbors.append(index - 1) }
                if x + 1 < width { neighbors.append(index + 1) }
                if y > 0 { neighbors.append(index - width) }
                if y + 1 < height { neighbors.append(index + width) }
                for neighbor in neighbors where !seen[neighbor] && alpha[neighbor] > 45 {
                    seen[neighbor] = true; queue.append(neighbor)
                }
            }
            components.append(component)
        }
        // Yoga cells contain a single connected robot; omit neighbouring-row fragments.
        let largest = components.map(\.count).max() ?? 0
        let threshold = primaryOnly ? largest : max(32, largest / 100)
        let main = components.filter { $0.count >= threshold }
        guard !main.isEmpty else { return CGRect(x: 0, y: 0, width: width, height: height) }
        let left = max(0, main.map(\.left).min()! - 2), top = max(0, main.map(\.top).min()! - 2)
        let right = min(width - 1, main.map(\.right).max()! + 2), bottom = min(height - 1, main.map(\.bottom).max()! + 2)
        return CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1)
    }
}
