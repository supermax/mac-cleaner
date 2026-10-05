import SwiftUI
import AppKit

@MainActor
final class CleanerViewModel: ObservableObject {
    @Published var items: [ScannedTarget] = []
    @Published var selection: Set<String> = []
    @Published var isScanning = false
    @Published var status = "Ready to scan your developer caches."
    @Published var showingConfirmation = false
    @Published var showingAbout = false

    init() { scan() }

    var selectedBytes: Int64 { items.filter { selection.contains($0.id) }.reduce(0) { $0 + $1.bytes } }
    var foundBytes: Int64 { items.reduce(0) { $0 + $1.bytes } }
    var selectedItems: [ScannedTarget] { items.filter { selection.contains($0.id) } }
    var allItemsSelected: Bool { !items.isEmpty && selection.count == items.count }

    var openRelevantApps: [String] {
        let selectedCategories = Set(selectedItems.map(\.target.category))
        let knownApps: [(CleanupCategory, String, [String])] = [
            (.xcode, "Xcode", ["xcode"]),
            (.simulators, "Simulator", ["simulator"]),
            (.unity, "Unity", ["unity"]),
            (.android, "Android Studio", ["android studio", "androidstudio"]),
            (.browsers, "Google Chrome", ["google chrome", "chrome"]),
            (.browsers, "Safari", ["safari"]),
            (.ide, "VS Code", ["visual studio code", "vscode"]),
            (.ide, "JetBrains IDE", ["jetbrains", "intellij", "rider", "pycharm", "webstorm", "clion"]),
            (.containers, "Docker Desktop", ["docker"]),
            (.virtualMachines, "Parallels Desktop", ["parallels"]),
            (.virtualMachines, "VirtualBox", ["virtualbox"]),
            (.virtualMachines, "VMware Fusion", ["vmware"])
        ]
        let runningNames = NSWorkspace.shared.runningApplications.compactMap { app -> String? in
            let name = (app.localizedName ?? "") + " " + (app.bundleIdentifier ?? "")
            return name.lowercased()
        }
        return knownApps.compactMap { category, displayName, hints in
            guard selectedCategories.contains(category) else { return nil }
            return runningNames.contains { runningName in hints.contains { runningName.contains($0) } } ? displayName : nil
        }
        .removingDuplicates()
        .sorted()
    }

    func toggleAll() {
        if allItemsSelected { selection.removeAll() }
        else { selection = Set(items.map(\.id)) }
    }

    func scan() {
        isScanning = true
        status = "Scanning local developer caches…"
        Task.detached(priority: .userInitiated) {
            let targets = CleanupTarget.defaults + CleanupTarget.temporaryBuildArtifacts()
            let results = targets.compactMap { target -> ScannedTarget? in
                let bytes = DiskScanner.size(of: target.url)
                return bytes > 0 ? ScannedTarget(target: target, bytes: bytes) : nil
            }.sorted { $0.bytes > $1.bytes }
            await MainActor.run {
                self.items = results
                self.selection = Set(results.filter { $0.target.defaultSelected }.map(\.id))
                self.isScanning = false
                self.status = results.isEmpty ? "No known cleanup locations contain files." : "Found \(Self.formatter.string(fromByteCount: self.foundBytes)). Review the selections before cleaning."
            }
        }
    }

    func clean() {
        let urls = selectedItems.map { $0.target.url }
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.recycle(urls) { _, error in
            DispatchQueue.main.async {
                if let error { self.status = "Could not move every item to the Trash: \(error.localizedDescription)" }
                else { self.status = "Moved \(Self.formatter.string(fromByteCount: self.selectedBytes)) to the Trash. Empty Trash to reclaim the disk space." }
                self.showingConfirmation = false
                self.scan()
            }
        }
    }

    static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter(); formatter.allowedUnits = [.useGB, .useMB, .useKB]; formatter.countStyle = .file
        return formatter
    }()
}

struct ContentView: View {
    @StateObject private var model = CleanerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.isScanning && model.items.isEmpty {
                Spacer(); ProgressView("Measuring folders…").controlSize(.large); Spacer()
            } else if model.items.isEmpty {
                ContentUnavailableView("Nothing to clean here", systemImage: "checkmark.circle", description: Text("The developer cache locations DevSpace checks are empty."))
            } else {
                List {
                    ForEach(model.items) { item in
                        CleanupRow(
                            item: item,
                            isSelected: Binding(
                                get: { model.selection.contains(item.id) },
                                set: { selected in
                                    if selected { model.selection.insert(item.id) }
                                    else { model.selection.remove(item.id) }
                                }
                            )
                        )
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            Divider()
            footer
        }
        .alert(confirmationTitle, isPresented: $model.showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button(model.openRelevantApps.isEmpty ? "Move to Trash" : "Move Anyway", role: .destructive) { model.clean() }
        } message: {
            Text(confirmationMessage)
        }
        .alert("About DevSpace", isPresented: $model.showingAbout) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("DevSpace only scans the listed locations in your home folder. It never runs with administrator privileges and moves selected folders to the Trash rather than deleting them permanently.")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Image(systemName: "internaldrive.fill").font(.system(size: 28)).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 3) {
                Text("DevSpace").font(.title2.weight(.bold))
                Text("A safe cleanup pass for game-development machines").foregroundStyle(.secondary)
            }
            Spacer()
            Button { model.showingAbout = true } label: { Image(systemName: "info.circle") }.buttonStyle(.plain).help("How DevSpace works")
            Button { model.toggleAll() } label: {
                Label(model.allItemsSelected ? "Deselect all" : "Select all", systemImage: model.allItemsSelected ? "square" : "checkmark.square")
            }
            .disabled(model.items.isEmpty || model.isScanning)
            Button { model.scan() } label: { Label("Scan again", systemImage: "arrow.clockwise") }
                .disabled(model.isScanning)
        }
        .padding(22)
    }

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.status).foregroundStyle(.secondary).lineLimit(2)
                if !model.isScanning { Text("Selected: \(CleanerViewModel.formatter.string(fromByteCount: model.selectedBytes))").font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            Button("Move Selected to Trash", systemImage: "trash") { model.showingConfirmation = true }
                .buttonStyle(.borderedProminent)
                .disabled(model.selection.isEmpty || model.isScanning)
        }
        .padding(18)
    }

    private var confirmationMessage: String {
        let size = CleanerViewModel.formatter.string(fromByteCount: model.selectedBytes)
        let openApps = model.openRelevantApps
        if openApps.isEmpty {
            return "\(size) will be moved to the Trash. This is reversible until you empty the Trash. Quit Xcode, Unity, Android Studio, Docker Desktop, browsers, and IDEs before cleaning any of their caches."
        }
        return "\(size) will be moved to the Trash. This is reversible until you empty the Trash. Quit these open related apps first: \(openApps.joined(separator: ", "))."
    }

    private var confirmationTitle: String {
        model.openRelevantApps.isEmpty ? "Move selected files to Trash?" : "Quit running apps before cleanup"
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

private struct CleanupRow: View {
    let item: ScannedTarget
    @Binding var isSelected: Bool
    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: $isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .help(isSelected ? "Remove from cleanup selection" : "Add to cleanup selection")
            Image(systemName: item.target.category.icon).font(.title3).foregroundStyle(color(for: item.target.category)).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.target.title).fontWeight(.semibold)
                Text(item.target.explanation).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                HStack(spacing: 6) {
                    Text(item.target.safety.label)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(item.target.safety == .regenerable ? Color.green.opacity(0.15) : Color.orange.opacity(0.16), in: Capsule())
                        .foregroundStyle(item.target.safety == .regenerable ? .green : .orange)
                    Text(item.target.url.path).font(.caption2.monospaced()).foregroundStyle(.tertiary).lineLimit(1)
                }
            }
            Spacer()
            Text(CleanerViewModel.formatter.string(fromByteCount: item.bytes)).font(.headline.monospacedDigit())
        }
        .padding(.vertical, 6)
    }
    private func color(for category: CleanupCategory) -> Color {
        switch category {
        case .xcode: .blue
        case .simulators: .purple
        case .unity: .orange
        case .android: .green
        case .containers: .teal
        case .ide: .pink
        case .packages: .yellow
        case .languages: .mint
        case .virtualMachines: .red
        case .browsers: .cyan
        case .downloads: .indigo
        }
    }
}
