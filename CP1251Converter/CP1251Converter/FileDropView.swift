import Cocoa
import UniformTypeIdentifiers

final class FileDropView: NSView {
    var onFileDropped: ((URL) -> Void)?
    var fileName: String? {
        didSet {
            needsDisplay = true
        }
    }

    private var isDraggingInside = false {
        didSet {
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard fileURL(from: sender) != nil else {
            return []
        }

        isDraggingInside = true
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDraggingInside = false
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        fileURL(from: sender) != nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDraggingInside = false

        guard let url = fileURL(from: sender) else {
            return false
        }

        onFileDropped?(url)
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = self.bounds.insetBy(dx: 1, dy: 1)
        let backgroundColor = isDraggingInside ? NSColor.controlAccentColor.withAlphaComponent(0.12) : NSColor.controlBackgroundColor
        let borderColor = isDraggingInside ? NSColor.controlAccentColor : NSColor.separatorColor
        let path = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)

        backgroundColor.setFill()
        path.fill()

        borderColor.setStroke()
        path.lineWidth = 2
        path.setLineDash([8, 5], count: 2, phase: 0)
        path.stroke()

        let headline = fileName ?? "Drop text file"
        let detail = fileName == nil ? "Drag a .txt file from Finder into this area" : "Selected file"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let headlineAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph
        ]
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph
        ]

        let headlineRect = NSRect(x: 16, y: bounds.midY + 4, width: bounds.width - 32, height: 24)
        let detailRect = NSRect(x: 16, y: bounds.midY - 24, width: bounds.width - 32, height: 20)

        headline.draw(in: headlineRect, withAttributes: headlineAttributes)
        detail.draw(in: detailRect, withAttributes: detailAttributes)
    }

    private func fileURL(from draggingInfo: NSDraggingInfo) -> URL? {
        let pasteboard = draggingInfo.draggingPasteboard

        if let urlString = pasteboard.string(forType: .fileURL),
           let url = URL(string: urlString),
           isTextLikeFile(url) {
            return url
        }

        guard let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return nil
        }

        return items.first(where: isTextLikeFile)
    }

    private func isTextLikeFile(_ url: URL) -> Bool {
        guard url.isFileURL else {
            return false
        }

        let allowedExtensions = ["txt", "csv", "srt", "sub", "log"]
        let pathExtension = url.pathExtension.lowercased()

        if allowedExtensions.contains(pathExtension) {
            return true
        }

        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return pathExtension.isEmpty
        }

        return type.conforms(to: .plainText) || type.conforms(to: .text)
    }
}
