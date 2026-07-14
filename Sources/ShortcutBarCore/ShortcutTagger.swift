import Foundation

public enum ShortcutTagger {
    public static func tags(for title: String, category: String = "", existing: [String] = []) -> [String] {
        var tags = Set(existing.flatMap(tokenize))
        tokenize(title).forEach { tags.insert($0) }
        tokenize(category).forEach { tags.insert($0) }

        let lower = title.lowercased()
        let categoryLower = category.lowercased()

        func add(_ values: String...) {
            values.flatMap(tokenize).forEach { tags.insert($0) }
        }

        if containsAny(lower, ["bold", "italic", "underline", "strikethrough", "highlight", "font", "color", "style", "format", "heading", "title", "subheading", "body", "monostyled"]) {
            add("label", "labels", "text", "format", "formatting", "style", "styles", "emphasis", "type")
        }

        if containsAny(lower, ["copy", "cut", "paste", "clipboard"]) {
            add("clipboard", "edit", "selection", "selected")
        }

        if containsAny(lower, ["find", "search", "replace", "spotlight"]) {
            add("search", "lookup", "locate", "filter", "query")
        }

        if containsAny(lower, ["tab", "window", "sidebar", "toolbar", "pane", "split", "full screen", "fullscreen"]) {
            add("view", "layout", "navigation", "navigate", "show", "hide")
        }

        if containsAny(lower, ["folder", "file", "trash", "alias", "duplicate", "eject", "server", "airdrop", "icloud", "downloads", "desktop", "documents"]) {
            add("finder", "file", "files", "folder", "folders", "location")
        }

        if containsAny(lower, ["reload", "reader", "bookmark", "history", "downloads", "address", "location", "web", "page", "private"]) {
            add("browser", "safari", "web", "website", "page", "url", "internet")
        }

        if containsAny(lower, ["reply", "forward", "archive", "mailbox", "message", "unread", "junk", "flag", "send", "get mail"]) {
            add("mail", "email", "inbox", "message", "messages")
        }

        if containsAny(lower, ["note", "checklist", "table", "list", "pin", "attachment", "scan"]) {
            add("notes", "note", "writing", "memo", "document")
        }

        if containsAny(lower, ["zoom", "actual size", "rotate", "markup", "crop", "pdf", "image", "thumbnail"]) {
            add("preview", "pdf", "image", "markup", "annotation")
        }

        if categoryLower.contains("file") {
            add("new", "open", "save", "print", "close")
        }

        if categoryLower.contains("edit") {
            add("undo", "redo", "clipboard", "selection")
        }

        if categoryLower.contains("view") {
            add("show", "hide", "display", "layout")
        }

        return tags.sorted()
    }

    static func tokenize(_ value: String) -> [String] {
        value
            .lowercased()
            .replacingOccurrences(of: "command", with: "cmd")
            .replacingOccurrences(of: "option", with: "opt")
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    private static func containsAny(_ value: String, _ needles: [String]) -> Bool {
        needles.contains { value.contains($0) }
    }
}
