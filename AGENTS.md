# DevSpace contributor guide

## Purpose

DevSpace is a local, native macOS cleanup assistant for game-development machines. It discovers reclaimable developer storage, explains what each item contains, and sends only user-selected items to Trash.

## Architecture

- `Sources/DevSpace/CleanupModels.swift` defines cleanup targets and their safety classification.
- `Sources/DevSpace/DiskScanner.swift` measures on-disk allocated size.
- `Sources/DevSpace/ContentView.swift` owns scanning, selection, running-app warnings, and cleanup UI.
- `Resources/` contains the app icon and bundle metadata.
- `scripts/build-app.sh` creates `dist/DevSpace.app`.

## Safety rules

- Never add a broad cleanup target for a system directory, `/private/var/folders`, `Library/Application Support`, or a whole home directory.
- Targets that may remove user data, VM disks, Docker data, simulator state, archives, or exports must be `reviewRequired` and unselected by default.
- Regenerable caches may default to selected, but their description must explain what is recreated and the expected cost (download/build time).
- Keep cleanup reversible: use `NSWorkspace.shared.recycle`; do not introduce permanent deletion.
- Detect relevant running applications before cleanup and preserve the explicit confirmation dialog.
- Temporary build-artifact discovery must stay narrowly scoped to known Unity/Xcode outputs inside the current user's temporary directory.

## Verification

```bash
swift build
./scripts/build-app.sh
codesign --verify --deep --strict --verbose=2 dist/DevSpace.app
```

For local work, launch the installed copy with `open -a DevSpace` after rebuilding and replacing `/Applications/DevSpace.app`.
