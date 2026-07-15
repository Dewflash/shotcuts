import AppKit
import Darwin
import SwiftUI

@main
@MainActor
final class ShortcutBarApp: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let appObserver = ActiveAppObserver()
    private var globalClickMonitor: Any?
    private var instanceLockDescriptor: Int32 = -1

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard acquireInstanceLock() else {
            return
        }

        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configurePopover()
        appObserver.start()

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                guard let self, self.popover.isShown else {
                    return
                }
                self.popover.performClose(event)
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.presentPopover()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        presentPopover()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        appObserver.stop()
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
        }
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
            button.imagePosition = .imageLeading
            button.title = "Shortcuts"
        } else {
            button.title = "Shortcuts"
        }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "ShortcutBar: Show shortcuts"
        button.setAccessibilityLabel("ShortcutBar shortcuts")
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 520, height: 620)
        popover.contentViewController = NSHostingController(
            rootView: ShortcutPopoverView(observer: appObserver)
        )
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }

        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu(relativeTo: button)
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            presentPopover()
        }
    }

    private func presentPopover() {
        guard let button = statusItem.button, !popover.isShown else {
            return
        }

        appObserver.refresh()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showStatusMenu(relativeTo button: NSStatusBarButton) {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: "Open Shortcuts",
            action: #selector(openPopoverFromMenu(_:)),
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

    @objc private func openPopoverFromMenu(_ sender: Any?) {
        togglePopover(sender)
    }

    @objc private func quitShortcutBar(_ sender: Any?) {
        NSApp.terminate(sender)
    }

    private func acquireInstanceLock() -> Bool {
        let lockURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("com.dewflash.shotcuts.lock")
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
