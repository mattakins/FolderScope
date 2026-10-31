# FolderScope

Native macOS sunburst folder visualization app (DaisyDisk-inspired).

## Stack
- Pure Swift + SwiftUI, macOS 14+
- Swift Package Manager with executable target
- Manual `.app` bundle (binary copied from `.build/debug/`)

## Build & Run
```bash
cd /Volumes/Ensemble/Repos/FolderScope
swift build && cp .build/debug/FolderScope FolderScope.app/Contents/MacOS/ && open FolderScope.app
```
Or use `./build.sh`.

## Project Structure
```
FolderScope/
├── Package.swift
├── FolderScope/
│   ├── FolderScopeApp.swift          # @main, AppDelegate, keyboard shortcuts
│   ├── ContentView.swift              # Routes: EmptyState / Scanning / MainView
│   ├── Models/
│   │   ├── FolderNode.swift           # Tree model: name, url, children, files, hue
│   │   └── AppState.swift             # @MainActor ObservableObject — state, nav, animation
│   ├── Core/
│   │   ├── DirectoryScanner.swift     # Actor-based async recursive scan, max depth 6
│   │   └── HitTester.swift            # Polar coordinate hit testing for sunburst segments
│   └── Views/
│       ├── SunburstCanvasView.swift   # SwiftUI Canvas — ring drawing, labels, hover, click
│       ├── BreadcrumbBar.swift        # Navigation breadcrumb + action buttons
│       ├── SidebarView.swift          # Tabs: Top 10 / Contents
│       ├── StatusBar.swift            # Hover info + threshold slider
│       ├── EmptyStateView.swift       # Folder picker / drag-drop prompt
│       └── ScanningView.swift         # Scanning progress
├── FolderScope.app/                   # Pre-created bundle shell
│   └── Contents/
│       ├── Info.plist
│       ├── MacOS/                     # Binary copied here after build
│       └── Resources/
└── build.sh
```

## Theme
Solarized Dark palette. All UI chrome colors use Solarized base tones:
- base03 `#002b36` — main background
- base02 `#073642` — panel background
- base01 `#586e75` — borders, muted text
- base0 `#839496` — body text
- base1 `#93a1a1` — emphasis text
- cyan `#2aa198` — accent (links, icons)
- orange `#cb4b16` — counts/highlights
- red `#dc322f` — button tint

Sunburst segments use hue-based coloring (color wheel) independent of the theme.

## Patterns
- `@MainActor ObservableObject` for AppState, passed via `.environmentObject()`
- `NotificationCenter` for keyboard shortcut dispatch (Cmd+O, Cmd+R, Cmd+[, Cmd+])
- `actor DirectoryScanner` for off-main-thread scanning
- SwiftUI `Canvas` for immediate-mode sunburst drawing
- Polar coordinate hit testing against stored segment array
- Timer-driven animation with easeOutCubic easing, staggered per-ring bloom

## Gotchas

- **Stale SPM build**: if changes aren't reflected after build, run `rm -rf .build` first to force a clean build.

## Reference
- Sunburst algorithms ported from: `/Users/matt/Sync/Retro/treemap-template.html`
- App structure patterns from: Knockout app in same Repos directory
