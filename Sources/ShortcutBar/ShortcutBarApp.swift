import AppKit
import SwiftUI

@main
@MainActor
final class ShortcutBarApp: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let appObserver = ActiveAppObserver()
    private var globalClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        appObserver.stop()
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "ShortcutBar") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "Cmd"
        }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.toolTip = "ShortcutBar"
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

        if popover.isShown {
            popover.performClose(sender)
        } else {
            appObserver.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
