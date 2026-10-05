import Foundation

enum CleanupCategory: String, CaseIterable, Hashable, Identifiable, Sendable {
    case xcode = "Xcode"
    case simulators = "Simulators"
    case unity = "Unity"
    case android = "Android"
    case containers = "Containers"
    case ide = "IDEs"
    case packages = "Package caches"
    case languages = "Language tools"
    case virtualMachines = "Virtual machines"
    case browsers = "Browsers"
    case downloads = "Downloads"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .xcode: "hammer.fill"
        case .simulators: "iphone"
        case .unity: "cube.fill"
        case .android: "antenna.radiowaves.left.and.right"
        case .containers: "shippingbox.fill"
        case .ide: "chevron.left.forwardslash.chevron.right"
        case .packages: "shippingbox.fill"
        case .languages: "curlybraces"
        case .virtualMachines: "macbook.and.iphone"
        case .browsers: "globe"
        case .downloads: "arrow.down.circle.fill"
        }
    }
    var tint: String {
        switch self {
        case .xcode: "blue"
        case .simulators: "purple"
        case .unity: "orange"
        case .android: "green"
        case .containers: "teal"
        case .ide: "pink"
        case .packages: "yellow"
        case .languages: "mint"
        case .virtualMachines: "red"
        case .browsers: "cyan"
        case .downloads: "indigo"
        }
    }
}

enum CleanupSafety: Equatable, Sendable {
    case regenerable
    case reviewRequired

    var label: String {
        switch self {
        case .regenerable: "Regenerable cache"
        case .reviewRequired: "Review required"
        }
    }
}

struct CleanupTarget: Identifiable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let relativePath: String
    let category: CleanupCategory
    let defaultSelected: Bool
    let safety: CleanupSafety
    let absolutePath: String?

    init(
        id: String,
        title: String,
        explanation: String,
        relativePath: String,
        category: CleanupCategory,
        defaultSelected: Bool,
        safety: CleanupSafety,
        absolutePath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.explanation = explanation
        self.relativePath = relativePath
        self.category = category
        self.defaultSelected = defaultSelected
        self.safety = safety
        self.absolutePath = absolutePath
    }

    var url: URL {
        if let absolutePath { return URL(fileURLWithPath: absolutePath, isDirectory: true) }
        return FileManager.default.homeDirectoryForCurrentUser.appending(path: relativePath)
    }

    static let defaults: [CleanupTarget] = [
        .init(id: "derived-data", title: "Derived Data", explanation: "Xcode build products, indexes, and logs. Recreated on the next build.", relativePath: "Library/Developer/Xcode/DerivedData", category: .xcode, defaultSelected: true, safety: .regenerable),
        .init(id: "xcode-docs", title: "Xcode Documentation Cache", explanation: "Downloaded documentation and search indexes. Xcode redownloads it as required.", relativePath: "Library/Developer/Shared/Documentation/DocSets", category: .xcode, defaultSelected: true, safety: .regenerable),
        .init(id: "xcode-archives", title: "Old Xcode Archives", explanation: "Archived app builds. Keep any archive you need for symbolication or export.", relativePath: "Library/Developer/Xcode/Archives", category: .xcode, defaultSelected: false, safety: .reviewRequired),
        .init(id: "device-support", title: "iOS Device Support", explanation: "Symbols copied from connected devices. Xcode downloads them again when required.", relativePath: "Library/Developer/Xcode/iOS DeviceSupport", category: .xcode, defaultSelected: true, safety: .regenerable),
        .init(id: "core-simulator", title: "CoreSimulator Data", explanation: "Installed simulator devices and their app data. This may remove simulator app state.", relativePath: "Library/Developer/CoreSimulator", category: .simulators, defaultSelected: false, safety: .reviewRequired),
        .init(id: "unity-cache", title: "Unity Asset Cache", explanation: "Unity's shared cache. Assets are reimported or downloaded as needed.", relativePath: "Library/Unity/cache", category: .unity, defaultSelected: true, safety: .regenerable),
        .init(id: "unity-package-cache", title: "Unity Package Cache", explanation: "Downloaded Unity packages. Projects restore packages from their manifests.", relativePath: "Library/Caches/com.unity3d.UnityEditor", category: .unity, defaultSelected: true, safety: .regenerable),
        .init(id: "gradle-cache", title: "Gradle Build Cache", explanation: "Android build dependencies and transforms. Gradle downloads them again if needed.", relativePath: ".gradle/caches", category: .android, defaultSelected: true, safety: .regenerable),
        .init(id: "gradle-distributions", title: "Gradle Distributions", explanation: "Downloaded Gradle versions. The wrapper downloads the required version again.", relativePath: ".gradle/wrapper/dists", category: .android, defaultSelected: true, safety: .regenerable),
        .init(id: "android-cache", title: "Android SDK Cache", explanation: "Temporary Android SDK downloads. The SDK manager recreates these files.", relativePath: ".android/cache", category: .android, defaultSelected: true, safety: .regenerable),
        .init(id: "android-avd", title: "Android Virtual Devices", explanation: "Android emulator images and device data. This may remove emulator state.", relativePath: ".android/avd", category: .android, defaultSelected: false, safety: .reviewRequired),
        .init(id: "google-cache", title: "Google IDE & Browser Cache", explanation: "Caches for Chrome and Android Studio. Browsing data, passwords, and projects are not included.", relativePath: "Library/Caches/Google", category: .browsers, defaultSelected: true, safety: .regenerable),
        .init(id: "safari-cache", title: "Safari Cache", explanation: "Browser cache only; saved passwords and bookmarks are unaffected.", relativePath: "Library/Caches/com.apple.Safari", category: .browsers, defaultSelected: true, safety: .regenerable),
        .init(id: "jetbrains-cache", title: "JetBrains IDE Cache", explanation: "Indexes and caches for Rider, IntelliJ, and other JetBrains tools. IDEs rebuild them.", relativePath: "Library/Caches/JetBrains", category: .ide, defaultSelected: true, safety: .regenerable),
        .init(id: "vscode-cache", title: "VS Code Cache", explanation: "Cached editor content and GPU data; extensions and settings are not included.", relativePath: "Library/Application Support/Code/Cache", category: .ide, defaultSelected: true, safety: .regenerable),
        .init(id: "vscode-cached-data", title: "VS Code Cached Data", explanation: "Regenerable Electron and extension cache data; settings and extensions are not included.", relativePath: "Library/Application Support/Code/CachedData", category: .ide, defaultSelected: true, safety: .regenerable),
        .init(id: "npm-cache", title: "npm Cache", explanation: "Downloaded Node package tarballs. npm fetches packages again on demand.", relativePath: ".npm", category: .packages, defaultSelected: true, safety: .regenerable),
        .init(id: "yarn-cache", title: "Yarn Cache", explanation: "Downloaded Yarn packages. Yarn restores them from lockfiles and registries.", relativePath: "Library/Caches/Yarn", category: .packages, defaultSelected: true, safety: .regenerable),
        .init(id: "pnpm-store", title: "pnpm Package Store", explanation: "Shared downloaded package content. pnpm recreates it on the next install.", relativePath: "Library/pnpm/store", category: .packages, defaultSelected: true, safety: .regenerable),
        .init(id: "nuget-packages", title: "NuGet Global Packages", explanation: "Restorable .NET packages. NuGet downloads them again during restore.", relativePath: ".nuget/packages", category: .packages, defaultSelected: true, safety: .regenerable),
        .init(id: "cocoapods-cache", title: "CocoaPods Cache", explanation: "Downloaded pod archives. CocoaPods recreates this cache on the next install.", relativePath: "Library/Caches/CocoaPods", category: .packages, defaultSelected: true, safety: .regenerable),
        .init(id: "swiftpm-cache", title: "Swift Package Cache", explanation: "Cached Swift package repositories and artifacts. SwiftPM refetches them as needed.", relativePath: ".swiftpm/cache", category: .packages, defaultSelected: true, safety: .regenerable),
        .init(id: "cargo-cache", title: "Cargo Registry Cache", explanation: "Downloaded Rust crates. Cargo downloads them again during a build.", relativePath: ".cargo/registry/cache", category: .languages, defaultSelected: true, safety: .regenerable),
        .init(id: "pip-cache", title: "pip Cache", explanation: "Downloaded Python package wheels and archives. pip recreates this cache when needed.", relativePath: "Library/Caches/pip", category: .languages, defaultSelected: true, safety: .regenerable),
        .init(id: "go-build-cache", title: "Go Build Cache", explanation: "Compiled Go build objects. Go rebuilds them automatically.", relativePath: "Library/Caches/go-build", category: .languages, defaultSelected: true, safety: .regenerable),
        .init(id: "homebrew-cache", title: "Homebrew Downloads", explanation: "Downloaded formula bottles and source archives. Homebrew downloads them again if required.", relativePath: "Library/Caches/Homebrew", category: .languages, defaultSelected: true, safety: .regenerable),
        .init(id: "docker-logs", title: "Docker Desktop Logs", explanation: "Diagnostic logs from Docker Desktop. Containers, images, and volumes are not included.", relativePath: "Library/Containers/com.docker.docker/Data/log", category: .containers, defaultSelected: true, safety: .regenerable),
        .init(id: "docker-managed-data", title: "Docker Desktop Managed Data", explanation: "Docker images, containers, volumes, and VM disk data. Quit Docker first; removing it resets Docker Desktop.", relativePath: "Library/Containers/com.docker.docker/Data/vms", category: .containers, defaultSelected: false, safety: .reviewRequired),
        .init(id: "parallels-vms", title: "Parallels Virtual Machines", explanation: "Complete Parallels VM bundles. Remove only machines you no longer need.", relativePath: "Parallels", category: .virtualMachines, defaultSelected: false, safety: .reviewRequired),
        .init(id: "virtualbox-vms", title: "VirtualBox VMs", explanation: "Complete VirtualBox VM images. Remove only machines you no longer need.", relativePath: "VirtualBox VMs", category: .virtualMachines, defaultSelected: false, safety: .reviewRequired),
        .init(id: "vmware-vms", title: "VMware Virtual Machines", explanation: "Complete VMware VM bundles. Remove only machines you no longer need.", relativePath: "Documents/Virtual Machines.localized", category: .virtualMachines, defaultSelected: false, safety: .reviewRequired),
        .init(id: "downloads", title: "Downloads", explanation: "Your Downloads folder. This is never selected automatically.", relativePath: "Downloads", category: .downloads, defaultSelected: false, safety: .reviewRequired)
    ]

    /// Finds only known Unity/Xcode output inside the current user's temporary directory.
    /// It deliberately never exposes the complete macOS temporary tree as a cleanup target.
    static func temporaryBuildArtifacts() -> [CleanupTarget] {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).standardizedFileURL
        guard temporaryDirectory.path.hasPrefix("/private/var/folders/") else { return [] }
        let manager = FileManager.default
        guard let entries = try? manager.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return entries.compactMap { entry -> CleanupTarget? in
            let name = entry.lastPathComponent
            let kind: String
            let explanation: String
            if name.hasPrefix("Unity-iPhone-") && name.hasSuffix(".xcarchive") {
                kind = "Unity iOS Archive"
                explanation = "Temporary Xcode archive from a Unity iOS export. Keep it only if you need this build for export or crash symbolication."
            } else if name.hasPrefix("Unity-iPhone-") && name.hasSuffix("-export") {
                kind = "Unity iOS Export Folder"
                explanation = "Temporary exported IPA/distribution output from a Unity iOS build. Keep it only if this export is still needed."
            } else if name.hasPrefix("Unity-iPhone_") && name.hasSuffix(".xcdistributionlogs") {
                kind = "Unity iOS Distribution Log"
                explanation = "Xcode distribution logs from a Unity iOS build. Safe to remove once the export has been verified."
            } else if name.hasPrefix("ResultBundle_") && name.hasSuffix(".xcresult") {
                kind = "Xcode Test Result Bundle"
                explanation = "Temporary Xcode test result bundle. Keep it only if you need to inspect its test reports or attachments."
            } else {
                return nil
            }

            return CleanupTarget(
                id: "temporary-" + entry.path,
                title: kind + " · " + name.replacingOccurrences(of: "Unity-iPhone-", with: "").replacingOccurrences(of: "ResultBundle_", with: ""),
                explanation: explanation,
                relativePath: "",
                category: .xcode,
                defaultSelected: false,
                safety: .reviewRequired,
                absolutePath: entry.path
            )
        }
    }
}

struct ScannedTarget: Identifiable, Sendable {
    let target: CleanupTarget
    let bytes: Int64
    var id: String { target.id }
}
