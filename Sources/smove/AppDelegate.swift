import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let shortcutStore = ShortcutStore()
    private let windowManager = WindowManager()
    private var hotKeyManager: HotKeyManager?
    private var statusItem: NSStatusItem?
    private var shortcuts: [Shortcut] = []
    private var shortcutSource = "Not loaded"
    private var registrationFailures: [String] = []
    private var hasRequestedAccessibility = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        requestAccessibilityIfNeeded()
        reloadShortcuts(nil)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = ""
        statusItem?.button?.image = DuckIcon.make(size: NSSize(width: 24, height: 18))
        statusItem?.button?.imagePosition = .imageOnly
        statusItem?.button?.toolTip = "smove"
        rebuildMenu()
    }

    @objc private func reloadShortcuts(_ sender: Any?) {
        let loaded = shortcutStore.loadShortcuts()
        shortcuts = loaded.shortcuts
        shortcutSource = loaded.source

        let manager = HotKeyManager()
        registrationFailures = manager.register(shortcuts: shortcuts) { [weak self] action in
            self?.perform(action)
        }
        hotKeyManager = manager
        rebuildMenu()
    }

    private func perform(_ action: WindowAction) {
        guard AXIsProcessTrusted() else {
            requestAccessibilityIfNeeded()
            rebuildMenu()
            return
        }

        windowManager.perform(action)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let title = menu.addItem(withTitle: "smove", action: nil, keyEquivalent: "")
        title.isEnabled = false

        let permissionTitle = AXIsProcessTrusted() ? "Accessibility: Allowed" : "Accessibility: Not Allowed"
        let permission = menu.addItem(withTitle: permissionTitle, action: nil, keyEquivalent: "")
        permission.isEnabled = false

        let shortcutCount = menu.addItem(withTitle: "Shortcuts: \(shortcuts.count)", action: nil, keyEquivalent: "")
        shortcutCount.isEnabled = false

        let source = menu.addItem(withTitle: "Source: \(shortcutSource)", action: nil, keyEquivalent: "")
        source.isEnabled = false

        if !registrationFailures.isEmpty {
            menu.addItem(.separator())
            let failed = menu.addItem(withTitle: "Hotkey Conflicts", action: nil, keyEquivalent: "")
            failed.isEnabled = false

            for failure in registrationFailures.prefix(6) {
                let item = menu.addItem(withTitle: failure, action: nil, keyEquivalent: "")
                item.isEnabled = false
            }

            if registrationFailures.count > 6 {
                let item = menu.addItem(withTitle: "+ \(registrationFailures.count - 6) more", action: nil, keyEquivalent: "")
                item.isEnabled = false
            }
        }

        addCheatSheet(to: menu)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Open Accessibility Settings", action: #selector(openAccessibilitySettings(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Reload Shortcuts", action: #selector(reloadShortcuts(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit smove", action: #selector(quit(_:)), keyEquivalent: "q")

        statusItem?.menu = menu
    }

    private func addCheatSheet(to menu: NSMenu) {
        menu.addItem(.separator())

        let header = menu.addItem(withTitle: "Cheat Sheet", action: nil, keyEquivalent: "")
        header.isEnabled = false

        for shortcut in shortcuts.sortedByCheatSheetOrder() {
            let item = menu.addItem(
                withTitle: "\(shortcut.action.displayName): \(format(binding: shortcut.keyBinding))",
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
        }
    }

    private func format(binding: String) -> String {
        binding
            .split(separator: "+")
            .map { part in
                switch part.lowercased() {
                case "ctrl": return "Control"
                case "alt": return "Option"
                case "cmd": return "Command"
                case "shift": return "Shift"
                case "left": return "Left"
                case "right": return "Right"
                case "up": return "Up"
                case "down": return "Down"
                default: return part.uppercased()
                }
            }
            .joined(separator: " + ")
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        guard !hasRequestedAccessibility else { return }

        hasRequestedAccessibility = true

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @objc private func openAccessibilitySettings(_ sender: Any?) {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]

        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) { return }
        }
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}
