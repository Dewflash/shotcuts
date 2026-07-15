import Foundation

public enum ShortcutSearch {
    public static func filter(_ shortcuts: [Shortcut], query: String) -> [Shortcut] {
        let terms = ShortcutTagger.tokenize(query)
        guard !terms.isEmpty else {
            return sort(shortcuts)
        }

        let normalizedQuery = terms.joined(separator: " ")
        return shortcuts.compactMap { shortcut -> SearchMatch? in
            let fields = SearchFields(shortcut: shortcut)
            guard terms.allSatisfy({ fields.blob.contains($0) }) else {
                return nil
            }

            return SearchMatch(
                shortcut: shortcut,
                score: score(
                    fields: fields,
                    terms: terms,
                    normalizedQuery: normalizedQuery
                )
            )
        }
        .sorted { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            return isAlphabeticallyBefore(lhs.shortcut, rhs.shortcut)
        }
        .map(\.shortcut)
    }

    public static func sort(_ shortcuts: [Shortcut]) -> [Shortcut] {
        shortcuts.sorted(by: isAlphabeticallyBefore)
    }

    public static func normalized(_ value: String) -> String {
        ShortcutTagger.tokenize(value).joined(separator: " ")
    }

    private static func score(
        fields: SearchFields,
        terms: [String],
        normalizedQuery: String
    ) -> Int {
        let titleMatches = terms.filter { fields.title.contains($0) }.count
        let titleContainsAll = titleMatches == terms.count
        let keysContainAll = terms.allSatisfy { fields.keys.contains($0) }
        let tagsContainAll = terms.allSatisfy { fields.tags.contains($0) }
        let categoryContainsAll = terms.allSatisfy { fields.category.contains($0) }

        if fields.title == normalizedQuery {
            return 1_000
        }
        if fields.title.hasPrefix(normalizedQuery) {
            return 900
        }
        if titleContainsAll && fields.title.contains(normalizedQuery) {
            return 800
        }
        if titleContainsAll {
            return 700 + titleMatches
        }
        if titleMatches > 0 {
            return 600 + titleMatches
        }
        if keysContainAll {
            return 500
        }
        if tagsContainAll {
            return 400
        }
        if categoryContainsAll {
            return 300
        }
        return 200
    }

    private static func isAlphabeticallyBefore(_ lhs: Shortcut, _ rhs: Shortcut) -> Bool {
        let titleOrder = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        if titleOrder != .orderedSame {
            return titleOrder == .orderedAscending
        }

        let keyOrder = lhs.keys.localizedCaseInsensitiveCompare(rhs.keys)
        if keyOrder != .orderedSame {
            return keyOrder == .orderedAscending
        }

        return lhs.source.localizedCaseInsensitiveCompare(rhs.source) == .orderedAscending
    }

    private struct SearchFields {
        let title: String
        let keys: String
        let category: String
        let tags: String
        let blob: String

        init(shortcut: Shortcut) {
            let enrichedTags = ShortcutTagger.tags(
                for: shortcut.title,
                category: shortcut.category,
                existing: shortcut.tags
            )

            title = normalized(shortcut.title)
            keys = normalized(shortcut.keys)
            category = normalized(shortcut.category)
            tags = normalized(enrichedTags.joined(separator: " "))
            blob = normalized(
                ([shortcut.source, shortcut.title, shortcut.keys, shortcut.category] + enrichedTags)
                    .joined(separator: " ")
            )
        }
    }

    private struct SearchMatch {
        let shortcut: Shortcut
        let score: Int
    }
}
