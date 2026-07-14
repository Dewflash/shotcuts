import Foundation

public enum ShortcutCatalog {
    public static func shortcuts(for identity: AppIdentity) -> [Shortcut] {
        let profile = profile(for: identity)
        var appSpecificShortcuts: [Shortcut] = []
        var contextualShortcuts: [Shortcut] = []

        if shouldIncludeTextEditing(for: profile, identity: identity) {
            contextualShortcuts += textEditingShortcuts
        }

        switch profile {
        case .finder:
            appSpecificShortcuts += finderShortcuts
        case .safari, .chrome, .browser:
            appSpecificShortcuts += browserShortcuts(source: identity.localizedName.isEmpty ? "Browser" : identity.localizedName)
        case .mail:
            appSpecificShortcuts += mailShortcuts
        case .notes:
            appSpecificShortcuts += notesShortcuts
        case .preview:
            appSpecificShortcuts += previewShortcuts
        case .textApp:
            appSpecificShortcuts += textAppShortcuts(source: identity.localizedName.isEmpty ? "Text App" : identity.localizedName)
        case .unknown:
            break
        }

        return deduplicated(appSpecificShortcuts + contextualShortcuts + commonShortcuts)
    }

    public static func merge(dynamic: [Shortcut], builtIn: [Shortcut]) -> [Shortcut] {
        deduplicated(dynamic + builtIn)
    }

    public static func deduplicated(_ shortcuts: [Shortcut]) -> [Shortcut] {
        var seen = Set<String>()
        var result: [Shortcut] = []

        for shortcut in shortcuts where !shortcut.keys.isEmpty {
            let key = shortcut.duplicateKey
            guard !seen.contains(key) else {
                continue
            }
            seen.insert(key)
            result.append(shortcut)
        }

        return result
    }

    private enum Profile {
        case finder
        case safari
        case chrome
        case browser
        case mail
        case notes
        case preview
        case textApp
        case unknown
    }

    private static func profile(for identity: AppIdentity) -> Profile {
        let bundleID = identity.bundleIdentifier?.lowercased() ?? ""
        let appName = identity.localizedName.lowercased()

        if bundleID == "com.apple.finder" || appName == "finder" {
            return .finder
        }
        if bundleID == "com.apple.safari" || appName.contains("safari") {
            return .safari
        }
        if bundleID.contains("chrome") || appName.contains("chrome") || appName.contains("arc") || appName.contains("brave") || appName.contains("edge") || appName.contains("firefox") {
            return bundleID.contains("chrome") ? .chrome : .browser
        }
        if bundleID == "com.apple.mail" || appName == "mail" {
            return .mail
        }
        if bundleID == "com.apple.notes" || appName == "notes" {
            return .notes
        }
        if bundleID == "com.apple.preview" || appName == "preview" {
            return .preview
        }
        if bundleID == "com.apple.textedit" || appName.contains("textedit") || appName.contains("pages") || appName.contains("word") || appName.contains("drafts") || appName.contains("ulysses") {
            return .textApp
        }

        return .unknown
    }

    private static func shouldIncludeTextEditing(for profile: Profile, identity: AppIdentity) -> Bool {
        switch profile {
        case .finder, .preview:
            return false
        case .safari, .chrome, .browser, .mail, .notes, .textApp, .unknown:
            return true
        }
    }

    private static func shortcut(
        _ source: String,
        _ title: String,
        _ keys: String,
        _ category: String,
        _ tags: [String] = []
    ) -> Shortcut {
        Shortcut(
            source: source,
            title: title,
            keys: keys,
            category: category,
            tags: ShortcutTagger.tags(for: title, category: category, existing: tags),
            origin: .builtIn
        )
    }

    private static let commonShortcuts: [Shortcut] = [
        shortcut("Common", "App Settings", "Cmd ,", "App", ["preferences", "settings"]),
        shortcut("Common", "Close Window or Tab", "Cmd W", "Window"),
        shortcut("Common", "Copy", "Cmd C", "Edit"),
        shortcut("Common", "Cut", "Cmd X", "Edit"),
        shortcut("Common", "Emoji and Symbols", "Ctrl Cmd Space", "Edit", ["character viewer"]),
        shortcut("Common", "Enter Full Screen", "Ctrl Cmd F", "View"),
        shortcut("Common", "Find", "Cmd F", "Edit"),
        shortcut("Common", "Find Next", "Cmd G", "Edit"),
        shortcut("Common", "Find Previous", "Shift Cmd G", "Edit"),
        shortcut("Common", "Force Quit", "Option Cmd Esc", "System"),
        shortcut("Common", "Hide App", "Cmd H", "App"),
        shortcut("Common", "Lock Screen", "Ctrl Cmd Q", "System"),
        shortcut("Common", "Minimize Window", "Cmd M", "Window"),
        shortcut("Common", "New", "Cmd N", "File"),
        shortcut("Common", "New Tab", "Cmd T", "File"),
        shortcut("Common", "Open", "Cmd O", "File"),
        shortcut("Common", "Paste", "Cmd V", "Edit"),
        shortcut("Common", "Paste and Match Style", "Option Shift Cmd V", "Edit", ["plain text"]),
        shortcut("Common", "Print", "Cmd P", "File"),
        shortcut("Common", "Quit App", "Cmd Q", "App"),
        shortcut("Common", "Redo", "Shift Cmd Z", "Edit"),
        shortcut("Common", "Save", "Cmd S", "File"),
        shortcut("Common", "Screenshot and Recording", "Shift Cmd 5", "System"),
        shortcut("Common", "Select All", "Cmd A", "Edit"),
        shortcut("Common", "Spotlight Search", "Cmd Space", "System"),
        shortcut("Common", "Switch Apps", "Cmd Tab", "System"),
        shortcut("Common", "Undo", "Cmd Z", "Edit")
    ]

    private static let textEditingShortcuts: [Shortcut] = [
        shortcut("Text", "Add Link", "Cmd K", "Format", ["label", "hyperlink", "url"]),
        shortcut("Text", "Align Center", "Shift Cmd |", "Format", ["paragraph", "label"]),
        shortcut("Text", "Align Left", "Cmd {", "Format", ["paragraph", "label"]),
        shortcut("Text", "Align Right", "Cmd }", "Format", ["paragraph", "label"]),
        shortcut("Text", "Bold", "Cmd B", "Format", ["label", "strong", "emphasis"]),
        shortcut("Text", "Copy Style", "Option Cmd C", "Format", ["label", "format painter"]),
        shortcut("Text", "Decrease Font Size", "Shift Cmd -", "Format", ["label", "smaller"]),
        shortcut("Text", "Delete Previous Word", "Option Delete", "Edit", ["word"]),
        shortcut("Text", "End of Document", "Cmd Down Arrow", "Navigation"),
        shortcut("Text", "End of Line", "Cmd Right Arrow", "Navigation"),
        shortcut("Text", "Forward Delete", "Fn Delete", "Edit"),
        shortcut("Text", "Increase Font Size", "Shift Cmd +", "Format", ["label", "larger"]),
        shortcut("Text", "Italic", "Cmd I", "Format", ["label", "emphasis"]),
        shortcut("Text", "Move One Word Left", "Option Left Arrow", "Navigation"),
        shortcut("Text", "Move One Word Right", "Option Right Arrow", "Navigation"),
        shortcut("Text", "Page Down", "Fn Down Arrow", "Navigation"),
        shortcut("Text", "Page Up", "Fn Up Arrow", "Navigation"),
        shortcut("Text", "Paste Style", "Option Cmd V", "Format", ["label"]),
        shortcut("Text", "Select to Document End", "Shift Cmd Down Arrow", "Selection"),
        shortcut("Text", "Select to Document Start", "Shift Cmd Up Arrow", "Selection"),
        shortcut("Text", "Select to Line End", "Shift Cmd Right Arrow", "Selection"),
        shortcut("Text", "Select to Line Start", "Shift Cmd Left Arrow", "Selection"),
        shortcut("Text", "Show Colors", "Shift Cmd C", "Format", ["label", "color"]),
        shortcut("Text", "Show Fonts", "Cmd T", "Format", ["label", "font"]),
        shortcut("Text", "Spelling and Grammar", "Shift Cmd :", "Edit"),
        shortcut("Text", "Start of Document", "Cmd Up Arrow", "Navigation"),
        shortcut("Text", "Start of Line", "Cmd Left Arrow", "Navigation"),
        shortcut("Text", "Underline", "Cmd U", "Format", ["label", "emphasis"])
    ]

    private static let finderShortcuts: [Shortcut] = [
        shortcut("Finder", "Add to Sidebar", "Ctrl Cmd T", "File"),
        shortcut("Finder", "Computer Folder", "Shift Cmd C", "Go"),
        shortcut("Finder", "Connect to Server", "Cmd K", "Go"),
        shortcut("Finder", "Desktop Folder", "Shift Cmd D", "Go"),
        shortcut("Finder", "Documents Folder", "Shift Cmd O", "Go"),
        shortcut("Finder", "Downloads Folder", "Option Cmd L", "Go"),
        shortcut("Finder", "Duplicate", "Cmd D", "File"),
        shortcut("Finder", "Eject", "Cmd E", "File"),
        shortcut("Finder", "Empty Trash", "Shift Cmd Delete", "File"),
        shortcut("Finder", "Gallery View", "Cmd 4", "View"),
        shortcut("Finder", "Get Info", "Cmd I", "File", ["metadata", "inspector"]),
        shortcut("Finder", "Go Back", "Cmd [", "Go"),
        shortcut("Finder", "Go Forward", "Cmd ]", "Go"),
        shortcut("Finder", "Go to Folder", "Shift Cmd G", "Go"),
        shortcut("Finder", "Home Folder", "Shift Cmd H", "Go"),
        shortcut("Finder", "Icon View", "Cmd 1", "View"),
        shortcut("Finder", "iCloud Drive", "Shift Cmd I", "Go"),
        shortcut("Finder", "List View", "Cmd 2", "View"),
        shortcut("Finder", "Make Alias", "Ctrl Cmd A", "File"),
        shortcut("Finder", "Move to Trash", "Cmd Delete", "File"),
        shortcut("Finder", "Network Folder", "Shift Cmd K", "Go"),
        shortcut("Finder", "New Finder Window", "Cmd N", "File"),
        shortcut("Finder", "New Folder", "Shift Cmd N", "File"),
        shortcut("Finder", "New Smart Folder", "Option Cmd N", "File"),
        shortcut("Finder", "Open Selected Item", "Cmd Down Arrow", "File"),
        shortcut("Finder", "Open Selected Folder", "Right Arrow", "Navigation"),
        shortcut("Finder", "Preview with Quick Look", "Space", "File"),
        shortcut("Finder", "Recents", "Shift Cmd F", "Go"),
        shortcut("Finder", "Show Enclosing Folder", "Cmd Up Arrow", "Go"),
        shortcut("Finder", "Show Path Bar", "Option Cmd P", "View"),
        shortcut("Finder", "Show Preview Pane", "Shift Cmd P", "View"),
        shortcut("Finder", "Show Sidebar", "Option Cmd S", "View"),
        shortcut("Finder", "Show Status Bar", "Cmd /", "View"),
        shortcut("Finder", "Show Tab Bar", "Shift Cmd T", "View"),
        shortcut("Finder", "Show View Options", "Cmd J", "View"),
        shortcut("Finder", "Utilities Folder", "Shift Cmd U", "Go")
    ]

    private static func browserShortcuts(source: String) -> [Shortcut] {
        [
            shortcut(source, "Actual Size", "Cmd 0", "View", ["zoom"]),
            shortcut(source, "Add Bookmark", "Cmd D", "Bookmarks"),
            shortcut(source, "Back", "Cmd [", "History"),
            shortcut(source, "Forward", "Cmd ]", "History"),
            shortcut(source, "New Private Window", "Shift Cmd N", "File", ["incognito"]),
            shortcut(source, "New Tab", "Cmd T", "File"),
            shortcut(source, "New Window", "Cmd N", "File"),
            shortcut(source, "Next Tab", "Ctrl Tab", "Window"),
            shortcut(source, "Open Location", "Cmd L", "File", ["address", "url", "search field"]),
            shortcut(source, "Previous Tab", "Ctrl Shift Tab", "Window"),
            shortcut(source, "Reload Page", "Cmd R", "View", ["refresh"]),
            shortcut(source, "Reopen Closed Tab", "Shift Cmd T", "History", ["restore"]),
            shortcut(source, "Show Downloads", "Option Cmd L", "View"),
            shortcut(source, "Show Reader", "Shift Cmd R", "View", ["reading"]),
            shortcut(source, "Stop Loading", "Esc", "View"),
            shortcut(source, "View Source", "Option Cmd U", "Develop"),
            shortcut(source, "Web Inspector", "Option Cmd I", "Develop"),
            shortcut(source, "Zoom In", "Cmd +", "View"),
            shortcut(source, "Zoom Out", "Cmd -", "View")
        ]
    }

    private static let mailShortcuts: [Shortcut] = [
        shortcut("Mail", "Archive Message", "Ctrl Cmd A", "Message"),
        shortcut("Mail", "Delete Message", "Cmd Delete", "Message"),
        shortcut("Mail", "Flag Message", "Shift Cmd L", "Message"),
        shortcut("Mail", "Forward", "Shift Cmd F", "Message"),
        shortcut("Mail", "Get New Mail", "Shift Cmd N", "Mailbox"),
        shortcut("Mail", "Mark as Junk", "Shift Cmd J", "Message"),
        shortcut("Mail", "Mark as Read or Unread", "Shift Cmd U", "Message"),
        shortcut("Mail", "New Message", "Cmd N", "File"),
        shortcut("Mail", "Reply", "Cmd R", "Message"),
        shortcut("Mail", "Reply All", "Shift Cmd R", "Message"),
        shortcut("Mail", "Search Mail", "Option Cmd F", "Edit"),
        shortcut("Mail", "Send Message", "Shift Cmd D", "Message"),
        shortcut("Mail", "Show Mailbox List", "Shift Cmd M", "View")
    ]

    private static let notesShortcuts: [Shortcut] = [
        shortcut("Notes", "Apply Body Style", "Shift Cmd B", "Format", ["label"]),
        shortcut("Notes", "Apply Heading Style", "Shift Cmd H", "Format", ["label"]),
        shortcut("Notes", "Apply Monostyled Style", "Shift Cmd M", "Format", ["label", "code"]),
        shortcut("Notes", "Apply Subheading Style", "Shift Cmd J", "Format", ["label"]),
        shortcut("Notes", "Apply Title Style", "Shift Cmd T", "Format", ["label"]),
        shortcut("Notes", "Bulleted List", "Shift Cmd 7", "Format", ["label"]),
        shortcut("Notes", "Checklist", "Shift Cmd L", "Format", ["todo", "task"]),
        shortcut("Notes", "Dashed List", "Shift Cmd 8", "Format", ["label"]),
        shortcut("Notes", "Decrease List Level", "Cmd [", "Format"),
        shortcut("Notes", "Highlight", "Ctrl Cmd H", "Format", ["label", "marker"]),
        shortcut("Notes", "Increase List Level", "Cmd ]", "Format"),
        shortcut("Notes", "Insert Table", "Option Cmd T", "Format"),
        shortcut("Notes", "New Folder", "Shift Cmd N", "File"),
        shortcut("Notes", "New Note", "Cmd N", "File"),
        shortcut("Notes", "Numbered List", "Shift Cmd 9", "Format", ["label"]),
        shortcut("Notes", "Search Notes", "Option Cmd F", "Edit"),
        shortcut("Notes", "Show Attachments Browser", "Cmd 1", "View"),
        shortcut("Notes", "Show Folders", "Option Cmd S", "View")
    ]

    private static let previewShortcuts: [Shortcut] = [
        shortcut("Preview", "Actual Size", "Cmd 0", "View"),
        shortcut("Preview", "Crop", "Cmd K", "Tools"),
        shortcut("Preview", "Export", "Option Cmd S", "File"),
        shortcut("Preview", "Next Page", "Down Arrow", "Go"),
        shortcut("Preview", "Previous Page", "Up Arrow", "Go"),
        shortcut("Preview", "Rotate Left", "Cmd L", "Tools"),
        shortcut("Preview", "Rotate Right", "Cmd R", "Tools"),
        shortcut("Preview", "Show Inspector", "Cmd I", "Tools"),
        shortcut("Preview", "Show Markup Toolbar", "Shift Cmd A", "View"),
        shortcut("Preview", "Show Thumbnails", "Option Cmd 2", "View"),
        shortcut("Preview", "Zoom In", "Cmd +", "View"),
        shortcut("Preview", "Zoom Out", "Cmd -", "View")
    ]

    private static func textAppShortcuts(source: String) -> [Shortcut] {
        [
            shortcut(source, "Bigger", "Cmd +", "Format", ["label", "font size"]),
            shortcut(source, "Smaller", "Cmd -", "Format", ["label", "font size"]),
            shortcut(source, "Show Ruler", "Cmd R", "Format"),
            shortcut(source, "Substitutions", "Ctrl Shift Cmd T", "Edit"),
            shortcut(source, "Transformations", "Ctrl Shift Cmd F", "Edit")
        ]
    }
}
