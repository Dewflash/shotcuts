import ApplicationServices
import Foundation
import ShortcutBarCore

enum MenuShortcutReader {
    static func frontWindowTitle(pid: pid_t) -> String? {
        let app = AXUIElementCreateApplication(pid)
        guard let window = elementAttribute(app, "AXFocusedWindow") else {
            return nil
        }
        return stringAttribute(window, "AXTitle")
    }

    static func shortcuts(pid: pid_t, appName: String) -> [Shortcut] {
        guard AXIsProcessTrusted() else {
            return []
        }

        let app = AXUIElementCreateApplication(pid)
        guard let menuBar = elementAttribute(app, "AXMenuBar") else {
            return []
        }

        var results: [Shortcut] = []
        visit(menuBar, path: [], appName: appName, results: &results)
        return ShortcutCatalog.deduplicated(results)
    }

    private static func visit(
        _ element: AXUIElement,
        path: [String],
        appName: String,
        results: inout [Shortcut]
    ) {
        let role = stringAttribute(element, "AXRole") ?? ""
        let title = cleanTitle(stringAttribute(element, "AXTitle"))
        let nextPath = title.isEmpty ? path : path + [title]

        if role == "AXMenuItem",
           !title.isEmpty,
           let keys = shortcutString(for: element) {
            let category = path.first ?? "Menu"
            results.append(
                Shortcut(
                    source: appName,
                    title: title,
                    keys: keys,
                    category: category,
                    tags: ShortcutTagger.tags(for: title, category: nextPath.joined(separator: " ")),
                    origin: .menuBar
                )
            )
        }

        guard let children = elementArrayAttribute(element, "AXChildren") else {
            return
        }

        for child in children {
            visit(child, path: nextPath, appName: appName, results: &results)
        }
    }

    private static func shortcutString(for element: AXUIElement) -> String? {
        let cmdChar = cleanShortcutKey(stringAttribute(element, "AXMenuItemCmdChar"))
        let glyph = intAttribute(element, "AXMenuItemCmdGlyph")
        let key = cmdChar.isEmpty ? glyphName(glyph) : cmdChar

        guard !key.isEmpty else {
            return nil
        }

        let modifiers = intAttribute(element, "AXMenuItemCmdModifiers") ?? 0
        let noCommand = (modifiers & 8) != 0
        var parts: [String] = []

        if !noCommand {
            parts.append("Cmd")
        }
        if (modifiers & 4) != 0 {
            parts.append("Ctrl")
        }
        if (modifiers & 2) != 0 {
            parts.append("Option")
        }
        if (modifiers & 1) != 0 {
            parts.append("Shift")
        }

        parts.append(key)
        return parts.joined(separator: " ")
    }

    private static func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else {
            return nil
        }
        return value as? String
    }

    private static func intAttribute(_ element: AXUIElement, _ attribute: String) -> Int? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else {
            return nil
        }
        return (value as? NSNumber)?.intValue
    }

    private static func elementAttribute(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let value else {
            return nil
        }
        return (value as! AXUIElement)
    }

    private static func elementArrayAttribute(_ element: AXUIElement, _ attribute: String) -> [AXUIElement]? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let value else {
            return nil
        }
        return value as? [AXUIElement]
    }

    private static func cleanTitle(_ value: String?) -> String {
        (value ?? "")
            .replacingOccurrences(of: "...", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanShortcutKey(_ value: String?) -> String {
        let raw = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            return ""
        }

        switch raw {
        case " ":
            return "Space"
        case "\r", "\n":
            return "Return"
        case "\u{1b}":
            return "Esc"
        default:
            return raw.count == 1 ? raw.uppercased() : raw
        }
    }

    private static func glyphName(_ glyph: Int?) -> String {
        guard let glyph else {
            return ""
        }

        switch glyph {
        case 0:
            return ""
        case 2:
            return "Tab"
        case 3:
            return "Return"
        case 4:
            return "Enter"
        case 5:
            return "Esc"
        case 9:
            return "Space"
        case 23:
            return "Delete"
        case 98:
            return "Up Arrow"
        case 99:
            return "Down Arrow"
        case 100:
            return "Left Arrow"
        case 101:
            return "Right Arrow"
        case 102:
            return "Page Up"
        case 103:
            return "Page Down"
        case 104:
            return "Home"
        case 105:
            return "End"
        default:
            return "Key \(glyph)"
        }
    }
}
