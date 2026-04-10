import AppKit
import Carbon

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventMonitor: Any?
    private var localMonitor: Any?
    private var onTrigger: (() -> Void)?

    private init() {}

    func register(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, action: @escaping () -> Void) {
        unregister()
        onTrigger = action

        // Global monitor (when app is not focused)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event, keyCode: keyCode, modifiers: modifiers)
        }

        // Local monitor (when app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.matchesShortcut(event, keyCode: keyCode, modifiers: modifiers) == true {
                self?.onTrigger?()
                return nil // consume the event
            }
            return event
        }
    }

    func unregister() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        onTrigger = nil
    }

    private func handleEvent(_ event: NSEvent, keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        if matchesShortcut(event, keyCode: keyCode, modifiers: modifiers) {
            onTrigger?()
        }
    }

    private func matchesShortcut(_ event: NSEvent, keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool {
        let mask: NSEvent.ModifierFlags = [.command, .option, .shift, .control]
        return event.keyCode == keyCode && event.modifierFlags.intersection(mask) == modifiers.intersection(mask)
    }

    // MARK: - Display helpers

    static func displayString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    static func keyName(for keyCode: UInt16) -> String {
        // Map common key codes to readable names
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
        ]
        return keyMap[keyCode] ?? "Key\(keyCode)"
    }
}
