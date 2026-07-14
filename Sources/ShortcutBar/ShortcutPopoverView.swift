import AppKit
import ShortcutBarCore
import SwiftUI

struct ShortcutPopoverView: View {
    @ObservedObject var observer: ActiveAppObserver
    @State private var searchText = ""
    @FocusState private var searchIsFocused: Bool

    private var builtInShortcuts: [Shortcut] {
        ShortcutCatalog.shortcuts(for: observer.snapshot.identity)
    }

    private var activeShortcuts: [Shortcut] {
        ShortcutCatalog.merge(
            dynamic: observer.menuShortcuts,
            builtIn: builtInShortcuts
        )
    }

    private var filteredShortcuts: [Shortcut] {
        ShortcutSearch.filter(activeShortcuts, query: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            shortcutList
            Divider()
            footer
        }
        .frame(width: 520, height: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            observer.refresh()
            searchIsFocused = true
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "keyboard")
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(observer.snapshot.appName)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                Text(observer.snapshot.windowTitle ?? "Menu shortcuts")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                observer.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("Refresh shortcuts")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search commands or tags", text: $searchText)
                .textFieldStyle(.plain)
                .focused($searchIsFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var shortcutList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filteredShortcuts.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredShortcuts) { shortcut in
                        ShortcutRow(shortcut: shortcut)
                        Divider()
                            .padding(.leading, 14)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text("No matching shortcuts")
                .font(.system(size: 13, weight: .medium))
            Text("Try a command, key, or tag")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text("\(filteredShortcuts.count) of \(activeShortcuts.count)")
                .foregroundStyle(.secondary)

            if observer.isScanningMenus {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.65)
                Text("Scanning")
                    .foregroundStyle(.secondary)
            } else if observer.accessibilityTrusted {
                Label("Live menus", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    observer.requestAccessibilityAccess()
                } label: {
                    Label("Enable live menus", systemImage: "lock.open")
                }
                .buttonStyle(.borderless)
                .help("Allow ShortcutBar to read the active app menu")
            }

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit ShortcutBar")
        }
        .font(.system(size: 12))
        .padding(.horizontal, 14)
        .frame(height: 34)
    }
}

private struct ShortcutRow: View {
    let shortcut: Shortcut

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(shortcut.category)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Text(shortcut.keys)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 8)
                .frame(minWidth: 72, alignment: .trailing)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}
