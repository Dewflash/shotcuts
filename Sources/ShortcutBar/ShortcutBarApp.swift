import AppKit
import SwiftUI

@main
@MainActor
final class ShortcutBarApp: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let appObserver = ActiveAppObserver()
    private var globalClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard keepSingleInstance() else {
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
            appObserver.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
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

    private func keepSingleInstance() -> Bool {
        let currentProcessID = ProcessInfo.processInfo.processIdentifier
        let bundleIdentifier = Bundle.main.bundleIdentifier
        let bundleURL = Bundle.main.bundleURL.standardizedFileURL
        let existingInstance = NSWorkspace.shared.runningApplications.first { application in
            guard application.processIdentifier != currentProcessID else {
                return false
            }

            let sameBundle = application.bundleURL?.standardizedFileURL == bundleURL
            let sameIdentifier = bundleIdentifier != nil && application.bundleIdentifier == bundleIdentifier
            return sameBundle || sameIdentifier
        }

        guard let existingInstance else {
            return true
        }

        existingInstance.activate(options: [.activateIgnoringOtherApps])
        NSApp.terminate(nil)
        return false
    }
}
