# ShortcutBar

ShortcutBar is a native macOS menu bar app that shows keyboard shortcuts for the app you are currently using.

Click the menu bar keyboard icon to open a transient shortcut panel. It closes when you click outside it or switch to another app. The search field filters commands by command name, key combo, category, and tags, so searches like `label`, `tab`, `mail`, `folder`, or `copy` surface the right shortcuts.

ShortcutBar has no Dock icon. Launching it opens the transient shortcut panel immediately; after that, left-click the menu bar item to show or hide it. Right-click the item for `Open Shortcuts` and `Quit ShortcutBar`. If it is launched more than once, the newest copy exits and leaves the first copy running.

## What it does

- Tracks the foreground macOS app with `NSWorkspace`.
- Closes itself when focus leaves the panel, so the app you choose opens unobstructed.
- Reads the active app menu bar through Accessibility when permission is enabled.
- Falls back to a bundled catalog for common macOS shortcuts plus Finder, Safari/browser, Mail, Notes, Preview, and text editing commands.
- Shows only verified live menu commands for apps outside the bundled catalog; it does not invent formatting or system shortcuts for unknown apps.
- Ranks title matches above key, tag, category, and source matches, then sorts alphabetically within each relevance tier.
- Packages as a normal `.app`, `.dmg`, and `.zip`.

## Repository layout

- `Sources/ShortcutBar/` contains the menu bar app, active-app tracking, Accessibility reader, and transient panel UI.
- `Sources/ShortcutBarCore/` contains shortcut models, catalogs, tags, and search logic.
- `Tests/` contains the catalog and search tests.
- `Packaging/` contains the app bundle metadata and generated app icon assets.
- `scripts/` contains the app and release packaging commands.
- `outputs/` contains generated release artifacts.

## Build

```sh
./scripts/build-mac-app.sh
```

The built app is written to:

```text
outputs/ShortcutBar.app
```

## Package

```sh
./scripts/package-release.sh
```

Release files are written to:

```text
outputs/ShortcutBar-1.0.dmg
outputs/ShortcutBar-1.0.zip
```

## Accessibility

The app works without Accessibility permission using the bundled catalog. Live menu access is needed only to read the active app's verified `AXMenuBar` and `AXMenuItem` titles and shortcut metadata. ShortcutBar does not capture the screen or monitor keystrokes. Enable live menus from the footer of the panel when you want exact commands for apps outside the bundled catalog.
