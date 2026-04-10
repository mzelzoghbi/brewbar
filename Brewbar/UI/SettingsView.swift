import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject private var settings = BrewbarSettings.shared

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            NetworkSettingsView(settings: settings)
                .tabItem {
                    Label("Network", systemImage: "network")
                }

            ColorPickerSettingsView(settings: settings)
                .tabItem {
                    Label("Color Picker", systemImage: "eyedropper")
                }
        }
        .frame(width: 520, height: 320)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: BrewbarSettings

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Launch at Login")
                        .frame(width: 180, alignment: .trailing)
                    Toggle("", isOn: $settings.launchAtLogin)
                        .labelsHidden()
                        .onChange(of: settings.launchAtLogin) { _, newValue in
                            setLaunchAtLogin(newValue)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            VStack(spacing: 4) {
                Text("Brewbar v0.1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Crafted with love by Zak in Egypt")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
        }
        .padding(24)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}

struct NetworkSettingsView: View {
    @ObservedObject var settings: BrewbarSettings

    private let intervals: [TimeInterval] = [1, 5, 10, 20, 30]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Update Interval")
                    .frame(width: 180, alignment: .trailing)
                Picker("", selection: $settings.networkUpdateInterval) {
                    ForEach(intervals, id: \.self) { interval in
                        Text("\(Int(interval))s").tag(interval)
                    }
                }
                .labelsHidden()
                .frame(width: 80)
            }

            HStack {
                Text("Display Unit")
                    .frame(width: 180, alignment: .trailing)
                Picker("", selection: $settings.networkDisplayUnit) {
                    ForEach(NetworkDisplayUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .labelsHidden()
                .frame(width: 80)
            }

            HStack {
                Text("Show Upload Speed")
                    .frame(width: 180, alignment: .trailing)
                Toggle("", isOn: $settings.networkShowUpload)
                    .labelsHidden()
            }

            HStack {
                Text("Show Download Speed")
                    .frame(width: 180, alignment: .trailing)
                Toggle("", isOn: $settings.networkShowDownload)
                    .labelsHidden()
            }

            HStack {
                Text("Vertical Layout")
                    .frame(width: 180, alignment: .trailing)
                Toggle("", isOn: $settings.networkLayoutVertical)
                    .labelsHidden()
                Text("Stack upload/download in a column")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Bandwidth Alert Threshold")
                    .frame(width: 180, alignment: .trailing)
                TextField("", value: $settings.networkBandwidthAlertThreshold, format: .number)
                    .frame(width: 60)
                Text("Mbps")
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ColorPickerSettingsView: View {
    @ObservedObject var settings: BrewbarSettings
    @State private var isRecording = false

    private var shortcutDisplay: String {
        HotkeyManager.displayString(
            keyCode: settings.colorPickerKeyCode,
            modifiers: NSEvent.ModifierFlags(rawValue: settings.colorPickerModifiers)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Keyboard Shortcut")
                    .frame(width: 180, alignment: .trailing)

                ShortcutRecorderView(
                    keyCode: $settings.colorPickerKeyCode,
                    modifiers: $settings.colorPickerModifiers,
                    isRecording: $isRecording
                )
            }

            HStack {
                Text("")
                    .frame(width: 180, alignment: .trailing)
                Text("Press the shortcut anywhere to pick a color from screen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var keyCode: UInt16
    @Binding var modifiers: UInt
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onShortcutRecorded = { newKeyCode, newModifiers in
            keyCode = newKeyCode
            modifiers = newModifiers.rawValue
            isRecording = false
            // Re-register the hotkey with new shortcut
            AppDelegate.shared?.registerColorPickerHotkey()
        }
        view.onRecordingChanged = { recording in
            isRecording = recording
        }
        view.updateDisplay(keyCode: keyCode, modifiers: NSEvent.ModifierFlags(rawValue: modifiers))
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        if !isRecording {
            nsView.updateDisplay(keyCode: keyCode, modifiers: NSEvent.ModifierFlags(rawValue: modifiers))
        }
    }
}

final class ShortcutRecorderNSView: NSView {
    var onShortcutRecorded: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    var onRecordingChanged: ((Bool) -> Void)?

    private let label = NSTextField(labelWithString: "")
    private let button = NSButton(title: "Record", target: nil, action: nil)
    private var isRecording = false
    private var localMonitor: Any?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        label.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        label.alignment = .center
        label.backgroundColor = NSColor.controlBackgroundColor
        label.isBordered = true
        label.isBezeled = true
        label.bezelStyle = .roundedBezel
        label.translatesAutoresizingMaskIntoConstraints = false

        button.target = self
        button.action = #selector(toggleRecording)
        button.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        addSubview(button)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 120),
            label.heightAnchor.constraint(equalToConstant: 24),

            button.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: 28),
            widthAnchor.constraint(equalToConstant: 220),
        ])
    }

    func updateDisplay(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        label.stringValue = HotkeyManager.displayString(keyCode: keyCode, modifiers: modifiers)
    }

    @objc private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        button.title = "Stop"
        label.stringValue = "Press shortcut..."
        label.textColor = .systemOrange
        onRecordingChanged?(true)

        // Temporarily unregister the hotkey so it doesn't fire while recording
        HotkeyManager.shared.unregister()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            let mask: NSEvent.ModifierFlags = [.command, .option, .shift, .control]
            let mods = event.modifierFlags.intersection(mask)

            // Require at least one modifier
            guard !mods.isEmpty else { return nil }

            self.onShortcutRecorded?(event.keyCode, mods)
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        button.title = "Record"
        label.textColor = .labelColor
        onRecordingChanged?(false)

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}

