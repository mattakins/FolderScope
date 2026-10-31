<h1 align="center">FolderScope</h1>

<p align="center">
  A native macOS app that shows where the items in a folder live, as an interactive sunburst chart.
</p>

---

## What it does

- Scans a folder and draws its contents as concentric rings.
- The center circle is the folder you are viewing.
- Each ring is one level deeper; each slice is a subfolder.
- Slice size is the number of items (files and folders) inside it.
- Loose files in a folder are shown as their own lighter slice.

## Features

- **Hover** a slice to highlight its path and see its name and item count in the center.
- **Click** a slice to drill into it; click the center to go back up.
- **Right-click** any slice, or the center, to open it in Finder, copy its path, or open it in Terminal.
- **Breadcrumb bar** shows where you are and lets you jump back to any level.
- **Sidebar** lists the 10 largest folders and the contents of the current folder.
- **Threshold slider** hides slices below a minimum item count.
- **Zoom and pan** with pinch, two-finger scroll, or keyboard.
- **Drag and drop** a folder onto the window to scan it.
- Animated transitions between levels.
- Solarized Dark theme.

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘O | Open folder |
| ⌘R | Rescan |
| ⌘[ / ⌘] | Navigate back / forward |
| ⌘+ / ⌘− | Zoom in / out |
| ⌘0 | Reset zoom |

## Requirements

- macOS 14 or later
- Swift 5.9 or later (Xcode 15+ or the Swift toolchain)

## Build and run

```bash
git clone https://github.com/mattakins/FolderScope.git
cd FolderScope
./build.sh
```

`build.sh` builds a debug binary, copies it into `FolderScope.app`, and opens the app.

### Install a release build

```bash
swift build -c release
mkdir -p FolderScope.app/Contents/MacOS
cp .build/release/FolderScope FolderScope.app/Contents/MacOS/
codesign --force --deep -s - FolderScope.app
cp -R FolderScope.app /Applications/
```

The app is ad-hoc signed, so it runs on the Mac that built it.

## Limits

- Scans up to 6 levels deep.
- Shows up to 5 rings at a time; drill in to see deeper levels.
- Sizes are item counts, not bytes.

## Project layout

```
FolderScope/
├── FolderScopeApp.swift      # App entry, menus, keyboard shortcuts
├── ContentView.swift         # Empty / scanning / main view routing
├── Models/                   # Folder tree and app state
├── Core/                     # Directory scanner and hit testing
└── Views/                    # Sunburst canvas, sidebar, breadcrumb, status bar
```
