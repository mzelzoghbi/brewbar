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
