import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let dropView = FileDropView()
    private let statusLabel = NSTextField(labelWithString: "Drag a CP1251 text file here.")
    private let pathLabel = NSTextField(labelWithString: "No file selected")
    private let convertButton = NSButton(title: "Convert", target: nil, action: nil)
    private var selectedFileURL: URL?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        buildWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func buildMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let quitTitle = "Quit CP1251 Converter"

        appMenu.addItem(NSMenuItem(title: quitTitle, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 320),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CP1251 Converter"
        window.center()
        window.minSize = NSSize(width: 420, height: 280)

        let rootView = NSView()
        rootView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = rootView

        let titleLabel = NSTextField(labelWithString: "CP1251 to UTF-8")
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.alignment = .center

        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center

        pathLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.alignment = .center
        pathLabel.lineBreakMode = .byTruncatingMiddle

        dropView.translatesAutoresizingMaskIntoConstraints = false
        dropView.onFileDropped = { [weak self] url in
            self?.selectFile(url)
        }

        convertButton.target = self
        convertButton.action = #selector(convertSelectedFile)
        convertButton.bezelStyle = .rounded
        convertButton.keyEquivalent = "\r"
        convertButton.isEnabled = false

        let stack = NSStackView(views: [titleLabel, statusLabel, dropView, pathLabel, convertButton])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -24),

            dropView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            dropView.heightAnchor.constraint(equalToConstant: 135),

            pathLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            convertButton.widthAnchor.constraint(equalToConstant: 120)
        ])

        window.makeKeyAndOrderFront(nil)
    }

    private func selectFile(_ url: URL) {
        selectedFileURL = url
        convertButton.isEnabled = true
        pathLabel.stringValue = url.path
        statusLabel.stringValue = "Ready to convert."
        dropView.fileName = url.lastPathComponent
    }

    @objc private func convertSelectedFile() {
        guard let url = selectedFileURL else {
            statusLabel.stringValue = "Please drag a file first."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let cp1251Encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.windowsCyrillic.rawValue))
            let encoding = String.Encoding(rawValue: cp1251Encoding)

            guard let contents = String(data: data, encoding: encoding) else {
                statusLabel.stringValue = "Could not read this file as CP1251."
                NSSound.beep()
                return
            }

            try contents.write(to: url, atomically: true, encoding: .utf8)
            statusLabel.stringValue = "Converted to UTF-8."
        } catch {
            statusLabel.stringValue = "Conversion failed: \(error.localizedDescription)"
            NSSound.beep()
        }
    }
}
