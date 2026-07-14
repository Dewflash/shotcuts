import Foundation

public struct AppIdentity: Equatable, Sendable {
    public let localizedName: String
    public let bundleIdentifier: String?

    public init(localizedName: String, bundleIdentifier: String?) {
        self.localizedName = localizedName
        self.bundleIdentifier = bundleIdentifier
    }
}

public enum ShortcutOrigin: String, Sendable {
    case builtIn
    case menuBar
}

public struct Shortcut: Identifiable, Hashable, Sendable {
    public let source: String
    public let title: String
    public let keys: String
    public let category: String
    public let tags: [String]
    public let origin: ShortcutOrigin

    public var id: String {
        [source, category, title, keys, origin.rawValue].joined(separator: "|")
    }

    public init(
        source: String,
        title: String,
        keys: String,
        category: String,
        tags: [String] = [],
        origin: ShortcutOrigin = .builtIn
    ) {
        self.source = source
        self.title = title
        self.keys = keys
        self.category = category
        self.tags = Array(Set(tags)).sorted()
        self.origin = origin
    }

    var duplicateKey: String {
        ShortcutSearch.normalized([title, keys].joined(separator: " "))
    }
}
