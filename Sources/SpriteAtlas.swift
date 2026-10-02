import AppKit

/// Loads the artist's uniform atlas into animation cells. Tiny disconnected alpha
/// specks outside the main silhouette are ignored when finding cell bounds.
final class SpriteAtlas {
    struct Frame {
        let image: NSImage
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

    init?(url: URL, columns: Int = 4, rows: Int = 4, rowFractions: [Double]? = nil, additionalURL: URL? = nil, latteURL: URL? = nil, interactionURL: URL? = nil, wellbeingURL: URL? = nil, discoURL: URL? = nil, clubURL: URL? = nil, stretchURL: URL? = nil) {
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
                let box = Self.silhouetteBounds(alpha, width: width, height: height)
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
        frames = output
    }

    private static func alphaBytes(_ image: CGImage) -> [UInt8] {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { buffer in
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo) else { return }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return (0..<(width * height)).map { pixels[$0 * 4 + 3] }
    }

    private static func silhouetteBounds(_ alpha: [UInt8], width: Int, height: Int) -> CGRect {
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
        let threshold = max(32, (components.map(\.count).max() ?? 0) / 100)
        let main = components.filter { $0.count >= threshold }
        guard !main.isEmpty else { return CGRect(x: 0, y: 0, width: width, height: height) }
        let left = max(0, main.map(\.left).min()! - 2), top = max(0, main.map(\.top).min()! - 2)
        let right = min(width - 1, main.map(\.right).max()! + 2), bottom = min(height - 1, main.map(\.bottom).max()! + 2)
        return CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1)
    }
}
