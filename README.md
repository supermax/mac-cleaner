# DevSpace

DevSpace is a local, native macOS cleanup app for game developers. It discovers reclaimable developer storage, explains what is safe to regenerate, and moves only explicitly selected items to macOS Trash.

![DevSpace icon](Resources/DevSpaceIcon.svg)

## What it checks

- Xcode derived data, device-support files, documentation caches, simulator data, archives, test results, and Unity iOS export artifacts.
- Unity, Android/Gradle, Docker, JetBrains, VS Code, and browser caches.
- npm, Yarn, pnpm, NuGet, CocoaPods, SwiftPM, Cargo, pip, Go, and Homebrew caches.
- Optional Docker, virtual-machine, emulator, archive, and Downloads locations as **Review required** items.

Green **Regenerable cache** items are safe to remove after closing their owning apps; the only cost is re-download or rebuild time. Orange **Review required** items can contain important state and are never selected automatically.

## Run

```bash
swift run
```

To open it as a regular app from Xcode, open `Package.swift`, choose the **DevSpace** scheme, and Run.

## Install in Applications

The app is packaged with a custom icon. Build it with `./scripts/build-app.sh`, then drag `dist/DevSpace.app` into Applications. The provided installer command will do this for you once during setup; after that, launch DevSpace from Launchpad, Spotlight, or your Applications folder.

## Development

Requirements: macOS 14+ and Xcode/Swift 6.

```bash
swift build
./scripts/build-app.sh
open dist/DevSpace.app
```

See [AGENTS.md](AGENTS.md) for the project architecture and the safety rules contributors and coding agents must follow.

## Safety notes

- It scans only the explicit locations shown in the app, all below your home folder.
- Downloads, Xcode Archives, and emulator data are not selected by default.
- It doesn't use administrator privileges or delete files permanently.
- Quit Xcode, Unity, Android Studio, and simulators before moving their cache folders to Trash.
- The app checks for relevant running apps and warns before cleanup, but you should still quit active builds, package installs, Docker, browsers, and IDEs first.
- A restart is usually unnecessary. If a process had an open deleted file, quitting it—or restarting—releases that space.
