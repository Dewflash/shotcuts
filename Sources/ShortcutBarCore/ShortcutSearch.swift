import Foundation

public enum ShortcutSearch {
    public static func filter(_ shortcuts: [Shortcut], query: String) -> [Shortcut] {
        let sorted = sort(shortcuts)
        let terms = ShortcutTagger.tokenize(query)
        guard !terms.isEmpty else {
            return sorted
        }

        return sorted.filter { shortcut in
            let haystack = normalized(searchBlob(for: shortcut))
            return terms.allSatisfy { haystack.contains($0) }
        }
    }

    public static func sort(_ shortcuts: [Shortcut]) -> [Shortcut] {
        shortcuts.sorted {
            let lhs = $0.title.localizedCaseInsensitiveCompare($1.title)
            if lhs != .orderedSame {
                return lhs == .orderedAscending
            }

            let rhs = $0.keys.localizedCaseInsensitiveCompare($1.keys)
            if rhs != .orderedSame {
                return rhs == .orderedAscending
            }

            return $0.source.localizedCaseInsensitiveCompare($1.source) == .orderedAscending
        }
    }

    public static func normalized(_ value: String) -> String {
        ShortcutTagger.tokenize(value).joined(separator: " ")
    }

    private static func searchBlob(for shortcut: Shortcut) -> String {
        let enrichedTags = ShortcutTagger.tags(
            for: shortcut.title,
            category: shortcut.category,
            existing: shortcut.tags
        )

        return ([shortcut.source, shortcut.title, shortcut.keys, shortcut.category] + enrichedTags)
            .joined(separator: " ")
    }
}
