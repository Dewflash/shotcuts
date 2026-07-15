import XCTest
@testable import ShortcutBarCore

final class ShortcutCatalogTests: XCTestCase {
    func testSafariCatalogContainsTabCommands() {
        let identity = AppIdentity(localizedName: "Safari", bundleIdentifier: "com.apple.Safari")
        let shortcuts = ShortcutCatalog.shortcuts(for: identity)

        XCTAssertTrue(shortcuts.contains { $0.title == "New Tab" && $0.keys == "Cmd T" })
        XCTAssertTrue(shortcuts.contains { $0.title == "Open Location" && $0.keys == "Cmd L" })
    }

    func testLabelSearchFindsFormattingCommands() {
        let identity = AppIdentity(localizedName: "Notes", bundleIdentifier: "com.apple.Notes")
        let results = ShortcutSearch.filter(ShortcutCatalog.shortcuts(for: identity), query: "label")
        let titles = Set(results.map(\.title))

        XCTAssertTrue(titles.contains("Bold"))
        XCTAssertTrue(titles.contains("Highlight"))
        XCTAssertTrue(titles.contains("Apply Heading Style"))
    }

    func testTaskSearchFindsChecklist() {
        let identity = AppIdentity(localizedName: "Notes", bundleIdentifier: "com.apple.Notes")
        let results = ShortcutSearch.filter(ShortcutCatalog.shortcuts(for: identity), query: "task")
        let titles = Set(results.map(\.title))

        XCTAssertTrue(titles.contains("Checklist"))
    }

    func testSearchPrioritizesTitleMatchesBeforeTagMatches() {
        let shortcuts = [
            Shortcut(source: "Test", title: "Open", keys: "Cmd O", category: "File"),
            Shortcut(source: "Test", title: "Open New Window", keys: "Cmd N", category: "Window"),
            Shortcut(source: "Test", title: "New Window", keys: "Cmd Shift N", category: "Window"),
            Shortcut(source: "Test", title: "New Tab", keys: "Cmd T", category: "File")
        ]

        let results = ShortcutSearch.filter(shortcuts, query: "new")

        XCTAssertEqual(
            results.map(\.title),
            ["New Tab", "New Window", "Open New Window", "Open"]
        )
    }

    func testUnknownAppsDoNotGetUnrelatedFallbackShortcuts() {
        let identity = AppIdentity(localizedName: "Activity Monitor", bundleIdentifier: "com.apple.ActivityMonitor")
        let shortcuts = ShortcutCatalog.shortcuts(for: identity)

        XCTAssertTrue(shortcuts.isEmpty)
        XCTAssertFalse(shortcuts.contains { $0.title == "Bold" })
        XCTAssertFalse(shortcuts.contains { $0.title == "Show Fonts" })
        XCTAssertFalse(shortcuts.contains { $0.title == "Spotlight Search" })
        XCTAssertFalse(shortcuts.contains { $0.title == "Switch Apps" })
    }

    func testSafariDoesNotGetTextEditingFallbackShortcuts() {
        let identity = AppIdentity(localizedName: "Safari", bundleIdentifier: "com.apple.Safari")
        let shortcuts = ShortcutCatalog.shortcuts(for: identity)

        XCTAssertFalse(shortcuts.contains { $0.title == "Bold" })
        XCTAssertFalse(shortcuts.contains { $0.title == "Underline" })
    }

    func testDynamicMenuShortcutsWinDeduping() {
        let dynamic = Shortcut(
            source: "Safari",
            title: "New Tab",
            keys: "Cmd T",
            category: "File",
            origin: .menuBar
        )
        let builtIn = ShortcutCatalog.shortcuts(
            for: AppIdentity(localizedName: "Safari", bundleIdentifier: "com.apple.Safari")
        )

        let merged = ShortcutCatalog.merge(dynamic: [dynamic], builtIn: builtIn)
        let matches = merged.filter { $0.title == "New Tab" && $0.keys == "Cmd T" }

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.origin, .menuBar)
    }
}
