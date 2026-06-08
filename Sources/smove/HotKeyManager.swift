import Carbon
import Foundation

private let smoveHotKeySignature = OSType(0x534D4F56) // SMOV

private let hotKeyEventHandler: EventHandlerUPP = { _, event, userData in
    guard let event, let userData else {
        return OSStatus(eventNotHandledErr)
    }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr, hotKeyID.signature == smoveHotKeySignature else {
        return OSStatus(eventNotHandledErr)
    }

    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.handleHotKey(id: hotKeyID.id)
    return noErr
}

final class HotKeyManager {
    private struct Registration {
        let reference: EventHotKeyRef
        let shortcut: Shortcut
    }

    private var eventHandler: EventHandlerRef?
    private var registrations: [UInt32: Registration] = [:]
    private var actionHandler: ((WindowAction) -> Void)?

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    deinit {
        unregisterAll()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func register(shortcuts: [Shortcut], handler: @escaping (WindowAction) -> Void) -> [String] {
        unregisterAll()
        actionHandler = handler

        var failures: [String] = []

        for (index, shortcut) in shortcuts.enumerated() {
            guard let combo = KeyCombo.parse(shortcut.keyBinding) else {
                failures.append("\(shortcut.action.displayName): unsupported key \(shortcut.keyBinding)")
                continue
            }

            let id = UInt32(index + 1)
            let hotKeyID = EventHotKeyID(signature: smoveHotKeySignature, id: id)
            var hotKeyRef: EventHotKeyRef?

            let status = RegisterEventHotKey(
                combo.keyCode,
                combo.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            guard status == noErr, let hotKeyRef else {
                failures.append("\(shortcut.action.displayName): \(describe(status: status))")
                continue
            }

            registrations[id] = Registration(reference: hotKeyRef, shortcut: shortcut)
        }

        return failures
    }

    private func unregisterAll() {
        for registration in registrations.values {
            UnregisterEventHotKey(registration.reference)
        }

        registrations.removeAll()
    }

    fileprivate func handleHotKey(id: UInt32) {
        guard let action = registrations[id]?.shortcut.action else { return }
        actionHandler?(action)
    }

    private func describe(status: OSStatus) -> String {
        switch status {
        case noErr:
            return "OK"
        case OSStatus(eventHotKeyExistsErr):
            return "already used by another app"
        default:
            return "registration failed (\(status))"
        }
    }
}
