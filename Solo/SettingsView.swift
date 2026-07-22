import AppKit
import KeyboardShortcuts
import SwiftUI
import UniformTypeIdentifiers

/// Settings content. Shortcut section per shortcut-config (recorder handles
/// recording, persistence, live re-registration, and detectable-conflict
/// warnings; clearing means "no shortcut" with the default shown as a hint).
/// Excluded Apps section per excluded-apps (shared list, add via running apps
/// or from disk, stale entries removable).
struct SettingsView: View {
    @State private var shortcut = KeyboardShortcuts.getShortcut(for: .toggleSoloFocus)
    @ObservedObject var excludedApps: ExcludedApps

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            KeyboardShortcuts.Recorder("Toggle Solo Focus:", name: .toggleSoloFocus) { newValue in
                shortcut = newValue
            }

            if shortcut == nil {
                Text("No shortcut set — Solo Focus is available from the menu bar only. The default was ⌃⌥⌘S; record it to bring it back.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("If the shortcut doesn't respond, another app may already be using it — record a different combination.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Divider()
                .padding(.vertical, 4)

            excludedSection
        }
        .padding(20)
        .frame(width: 400, alignment: .leading)
    }

    // MARK: - Excluded Apps

    private var rows: [(bundleId: String, name: String, icon: NSImage?)] {
        excludedApps.bundleIds
            .map { id in
                let info = ExcludedApps.displayInfo(for: id)
                return (id, info.name, info.icon)
            }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
    }

    private var excludedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Excluded Apps")
                .font(.headline)
            Text("Solo Focus never hides these apps, and Smart Restore never touches their windows.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if rows.isEmpty {
                Text("No excluded apps.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(rows, id: \.bundleId) { row in
                    HStack(spacing: 6) {
                        if let icon = row.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "app.dashed")
                                .frame(width: 18, height: 18)
                        }
                        Text(row.name)
                        Spacer()
                        Button {
                            excludedApps.remove(row.bundleId)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove from Excluded Apps")
                    }
                }
            }

            addMenu
        }
    }

    private var addMenu: some View {
        Menu("Add App…") {
            let running = runningCandidates
            if !running.isEmpty {
                Section("Running Apps") {
                    ForEach(running, id: \.bundleId) { app in
                        Button(app.name) { excludedApps.add(app.bundleId) }
                    }
                }
            }
            Button("Choose from Disk…") { chooseFromDisk() }
        }
        .frame(width: 180)
    }

    /// Regular running apps not already excluded (and not Solo itself).
    private var runningCandidates: [(bundleId: String, name: String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (String, String)? in
                guard let id = app.bundleIdentifier,
                      id != Bundle.main.bundleIdentifier,
                      !excludedApps.bundleIds.contains(id) else { return nil }
                return (id, app.localizedName ?? id)
            }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
    }

    private func chooseFromDisk() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url,
              let bundleId = Bundle(url: url)?.bundleIdentifier else { return }
        excludedApps.add(bundleId)
    }
}
