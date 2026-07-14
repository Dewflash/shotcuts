# ShortcutBar

ShortcutBar is a native macOS menu bar app that shows keyboard shortcuts for the app you are currently using.

Click the menu bar keyboard icon to open a popover. The search field filters commands by command name, key combo, category, and tags, so searches like `label`, `tab`, `mail`, `folder`, or `copy` surface the right shortcuts.

## What it does

- Tracks the foreground macOS app with `NSWorkspace`.
- Keeps showing the app you were using before opening the menu bar popover.
- Reads the active app menu bar through Accessibility when permission is enabled.
- Falls back to a bundled catalog for common macOS shortcuts plus Finder, Safari/browser, Mail, Notes, Preview, and text editing commands.
- Sorts commands alphabetically.
- Packages as a normal `.app`, `.dmg`, and `.zip`.

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

The app works without Accessibility permission using the bundled catalog. Enable live menus from the footer of the popover to let ShortcutBar read the actual active app menu items and current window title.
