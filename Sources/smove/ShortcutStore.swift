import AppKit
import Foundation

struct LoadedShortcuts {
    let shortcuts: [Shortcut]
    let source: String
}

final class ShortcutStore {
    private let fileManager = FileManager.default

    func loadShortcuts() -> LoadedShortcuts {
        if let loaded = loadFromSmoveSupport() {
            return loaded
        }

        if let loaded = importFromSpectacle() {
            return loaded
        }

        if let loaded = loadFromBundle() {
            return loaded
        }

        return LoadedShortcuts(shortcuts: decodeBuiltInShortcuts(), source: "Built-in defaults")
    }

    private func loadFromSmoveSupport() -> LoadedShortcuts? {
        let url = smoveShortcutsURL
        guard fileManager.fileExists(atPath: url.path), let shortcuts = decode(url: url) else {
            return nil
        }

        return LoadedShortcuts(shortcuts: shortcuts, source: "smove config")
    }

    private func importFromSpectacle() -> LoadedShortcuts? {
        let url = spectacleShortcutsURL
        guard fileManager.fileExists(atPath: url.path), let shortcuts = decode(url: url) else {
            return nil
        }

        do {
            try fileManager.createDirectory(at: smoveSupportDirectory, withIntermediateDirectories: true)

            if fileManager.fileExists(atPath: smoveShortcutsURL.path) {
                try fileManager.removeItem(at: smoveShortcutsURL)
            }

            try fileManager.copyItem(at: url, to: smoveShortcutsURL)
        } catch {
            return LoadedShortcuts(shortcuts: shortcuts, source: "Spectacle config")
        }

        return LoadedShortcuts(shortcuts: shortcuts, source: "Imported Spectacle config")
    }

    private func loadFromBundle() -> LoadedShortcuts? {
        guard let url = Bundle.main.url(forResource: "Shortcuts", withExtension: "json"),
              let shortcuts = decode(url: url) else {
            return nil
        }

        return LoadedShortcuts(shortcuts: shortcuts, source: "Bundled Spectacle config")
    }

    private func decode(url: URL) -> [Shortcut]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([Shortcut].self, from: data)
    }

    private func decodeBuiltInShortcuts() -> [Shortcut] {
        let data = Data(Self.builtInShortcuts.utf8)
        return (try? JSONDecoder().decode([Shortcut].self, from: data)) ?? []
    }

    private var smoveSupportDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("smove", isDirectory: true)
    }

    private var smoveShortcutsURL: URL {
        smoveSupportDirectory.appendingPathComponent("Shortcuts.json")
    }

    private var spectacleShortcutsURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base
            .appendingPathComponent("Spectacle", isDirectory: true)
            .appendingPathComponent("Shortcuts.json")
    }

    private static let builtInShortcuts = """
    [
      { "shortcut_key_binding" : "alt+shift+cmd+z", "shortcut_name" : "RedoLastMove" },
      { "shortcut_key_binding" : "ctrl+alt+shift+left", "shortcut_name" : "MakeSmaller" },
      { "shortcut_key_binding" : "ctrl+alt+left", "shortcut_name" : "MoveToPreviousThird" },
      { "shortcut_key_binding" : "ctrl+cmd+right", "shortcut_name" : "MoveToUpperRight" },
      { "shortcut_key_binding" : "alt+cmd+down", "shortcut_name" : "MoveToBottomHalf" },
      { "shortcut_key_binding" : "ctrl+alt+cmd+right", "shortcut_name" : "MoveToNextDisplay" },
      { "shortcut_key_binding" : "alt+cmd+up", "shortcut_name" : "MoveToTopHalf" },
      { "shortcut_key_binding" : "ctrl+shift+cmd+left", "shortcut_name" : "MoveToLowerLeft" },
      { "shortcut_key_binding" : "ctrl+alt+shift+right", "shortcut_name" : "MakeLarger" },
      { "shortcut_key_binding" : "alt+cmd+z", "shortcut_name" : "UndoLastMove" },
      { "shortcut_key_binding" : "ctrl+alt+cmd+left", "shortcut_name" : "MoveToPreviousDisplay" },
      { "shortcut_key_binding" : "alt+cmd+f", "shortcut_name" : "MoveToFullscreen" },
      { "shortcut_key_binding" : "ctrl+alt+right", "shortcut_name" : "MoveToNextThird" },
      { "shortcut_key_binding" : "alt+cmd+left", "shortcut_name" : "MoveToLeftHalf" },
      { "shortcut_key_binding" : "alt+cmd+c", "shortcut_name" : "MoveToCenter" },
      { "shortcut_key_binding" : "alt+cmd+right", "shortcut_name" : "MoveToRightHalf" },
      { "shortcut_key_binding" : "ctrl+shift+cmd+right", "shortcut_name" : "MoveToLowerRight" },
      { "shortcut_key_binding" : "ctrl+cmd+left", "shortcut_name" : "MoveToUpperLeft" }
    ]
    """
}
