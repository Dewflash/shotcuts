import AppKit
import Darwin
import SwiftUI

@MainActor
private final class TransientShortcutPanel: NSPanel {
    var dismissesWhenResigned = false

    override func resignKey() {
        super.resignKey()
        if dismissesWhenResigned {
            orderOut(nil)
        }
    }
}

@main
@MainActor
final class ShortcutBarApp: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let appObserver = ActiveAppObserver()
    private var shortcutWindow: TransientShortcutPanel?
    private var instanceLockDescriptor: Int32 = -1

    static func main() {
        let app = NSApplication.shared
        let delegate = ShortcutBarApp()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard acquireInstanceLock() else {
            return
        }

        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureShortcutWindow()
        appObserver.start()

        DispatchQueue.main.async { [weak self] in
            self?.presentShortcutWindow()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        presentShortcutWindow()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        appObserver.stop()
        releaseInstanceLock()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        statusItem.isVisible = true

        if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "ShortcutBar") {
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            button.title = "Shortcuts"
        }

        button.target = self
        button.action = #selector(toggleShortcutWindow(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "ShortcutBar: Show shortcuts"
        button.setAccessibilityLabel("ShortcutBar shortcuts")
    }

    private func configureShortcutWindow() {
        let panel = TransientShortcutPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 620),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "ShortcutBar"
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.contentViewController = NSHostingController(
            rootView: ShortcutPopoverView(observer: appObserver)
        )
        shortcutWindow = panel
    }

    @objc private func toggleShortcutWindow(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }

        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu(relativeTo: button)
            return
        }

        if shortcutWindow?.isVisible == true {
            shortcutWindow?.orderOut(sender)
        } else {
            presentShortcutWindow()
        }
    }

    private func presentShortcutWindow() {
        guard let window = shortcutWindow else {
            return
        }

        window.dismissesWhenResigned = false
        appObserver.refresh()
        if !window.isVisible {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak window] in
            guard let window, window.isVisible, window.isKeyWindow else {
                return
            }
            window.dismissesWhenResigned = true
        }
    }

    private func showStatusMenu(relativeTo button: NSStatusBarButton) {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: "Open Shortcuts",
            action: #selector(openShortcutWindowFromMenu(_:)),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit ShortcutBar",
            action: #selector(quitShortcutBar(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 4),
            in: button
        )
    }

    @objc private func openShortcutWindowFromMenu(_ sender: Any?) {
        presentShortcutWindow()
    }

    @objc private func quitShortcutBar(_ sender: Any?) {
        NSApp.terminate(sender)
    }

    private func acquireInstanceLock() -> Bool {
        let lockURL = URL(fileURLWithPath: "/tmp/com.dewflash.shotcuts.lock")
        let descriptor = Darwin.open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)

        guard descriptor >= 0 else {
            return true
        }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            NSApp.terminate(nil)
            return false
        }

        instanceLockDescriptor = descriptor
        return true
    }

    private func releaseInstanceLock() {
        guard instanceLockDescriptor >= 0 else {
            return
        }

        _ = flock(instanceLockDescriptor, LOCK_UN)
        close(instanceLockDescriptor)
        instanceLockDescriptor = -1
    }
}
