import AppKit
import ApplicationServices
import Foundation
import ShortcutBarCore

struct ActiveAppSnapshot: Equatable {
    let pid: pid_t?
    let appName: String
    let bundleIdentifier: String?
    let windowTitle: String?

    static let empty = ActiveAppSnapshot(
        pid: nil,
        appName: "Current App",
        bundleIdentifier: nil,
        windowTitle: nil
    )

    var identity: AppIdentity {
        AppIdentity(localizedName: appName, bundleIdentifier: bundleIdentifier)
    }
}

@MainActor
final class ActiveAppObserver: ObservableObject {
    @Published private(set) var snapshot: ActiveAppSnapshot = .empty
    @Published private(set) var menuShortcuts: [Shortcut] = []
    @Published private(set) var accessibilityTrusted = AXIsProcessTrusted()
    @Published private(set) var isScanningMenus = false

    private var appObserver: NSObjectProtocol?
    private var timer: Timer?
    private var menuReadToken = UUID()
    private let ownBundleID = Bundle.main.bundleIdentifier
    private let ownProcessID = ProcessInfo.processInfo.processIdentifier
    private var lastExternalApplication: NSRunningApplication?

    func start() {
        refresh()

        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            Task { @MainActor in
                if let application {
                    self?.refresh(application: application)
                } else {
                    self?.refresh()
                }
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        if let appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appObserver)
        }
        timer?.invalidate()
        timer = nil
    }

    func requestAccessibilityAccess() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refresh()
    }

    func refresh() {
        let wasAccessibilityTrusted = accessibilityTrusted
        accessibilityTrusted = AXIsProcessTrusted()

        guard let app = targetApplication() else {
            resetTarget()
            return
        }

        updateSnapshot(for: app, wasAccessibilityTrusted: wasAccessibilityTrusted)
    }

    private func refresh(application: NSRunningApplication) {
        guard !isOwnApplication(application) else {
            return
        }

        let wasAccessibilityTrusted = accessibilityTrusted
        accessibilityTrusted = AXIsProcessTrusted()
        lastExternalApplication = application
        updateSnapshot(for: application, wasAccessibilityTrusted: wasAccessibilityTrusted)
    }

    private func targetApplication() -> NSRunningApplication? {
        guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
            guard let lastExternalApplication, !lastExternalApplication.isTerminated else {
                return nil
            }
            return lastExternalApplication
        }

        if isOwnApplication(frontmostApplication) {
            guard let lastExternalApplication, !lastExternalApplication.isTerminated else {
                return nil
            }
            return lastExternalApplication
        }

        return frontmostApplication
    }

    private func updateSnapshot(for app: NSRunningApplication, wasAccessibilityTrusted: Bool) {
        guard !isOwnApplication(app) else {
            return
        }

        lastExternalApplication = app
        let bundleID = app.bundleIdentifier
        let title = accessibilityTrusted
            ? MenuShortcutReader.frontWindowTitle(pid: app.processIdentifier)
            : nil

        let nextSnapshot = ActiveAppSnapshot(
            pid: app.processIdentifier,
            appName: app.localizedName ?? "Current App",
            bundleIdentifier: bundleID,
            windowTitle: title
        )

        let changedApp = nextSnapshot.pid != snapshot.pid
        let changedTitle = nextSnapshot.windowTitle != snapshot.windowTitle
        let changedAccessibility = accessibilityTrusted != wasAccessibilityTrusted
        snapshot = nextSnapshot

        if changedApp || changedTitle || changedAccessibility || (accessibilityTrusted && menuShortcuts.isEmpty) {
            reloadMenuShortcuts(for: nextSnapshot)
        }
    }

    private func isOwnApplication(_ application: NSRunningApplication) -> Bool {
        let bundleMatches = ownBundleID != nil && application.bundleIdentifier == ownBundleID
        return application.processIdentifier == ownProcessID || bundleMatches
    }

    private func resetTarget() {
        lastExternalApplication = nil
        menuReadToken = UUID()
        snapshot = .empty
        menuShortcuts = []
        isScanningMenus = false
    }

    private func reloadMenuShortcuts(for snapshot: ActiveAppSnapshot) {
        guard accessibilityTrusted, let pid = snapshot.pid else {
            menuShortcuts = []
            isScanningMenus = false
            return
        }

        let token = UUID()
        menuReadToken = token
        isScanningMenus = true

        Task.detached(priority: .utility) {
            let shortcuts = MenuShortcutReader.shortcuts(pid: pid, appName: snapshot.appName)
            await MainActor.run { [weak self] in
                guard let self, self.menuReadToken == token else {
                    return
                }
                self.menuShortcuts = shortcuts
                self.isScanningMenus = false
            }
        }
    }

    deinit {
        timer?.invalidate()
        if let appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appObserver)
        }
    }
}
