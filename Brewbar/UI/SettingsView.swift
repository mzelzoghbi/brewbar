import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject private var settings = BrewbarSettings.shared
    @ObservedObject private var registry = ModuleRegistry.shared

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

            ModulesSettingsView(registry: registry)
                .tabItem {
                    Label("Modules", systemImage: "square.grid.2x2")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: BrewbarSettings

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
        }
        .padding()
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

    private let intervals: [TimeInterval] = [1, 2, 5, 10, 30]

    var body: some View {
        Form {
            Picker("Update Interval", selection: $settings.networkUpdateInterval) {
                ForEach(intervals, id: \.self) { interval in
                    Text("\(Int(interval))s").tag(interval)
                }
            }

            Picker("Display Unit", selection: $settings.networkDisplayUnit) {
                ForEach(NetworkDisplayUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }

            Toggle("Show Upload Speed", isOn: $settings.networkShowUpload)
            Toggle("Show Download Speed", isOn: $settings.networkShowDownload)

            HStack {
                Text("Bandwidth Alert Threshold")
                Spacer()
                TextField("MB/s", value: $settings.networkBandwidthAlertThreshold, format: .number)
                    .frame(width: 60)
                Text("MB/s")
            }
        }
        .padding()
    }
}

struct ModulesSettingsView: View {
    @ObservedObject var registry: ModuleRegistry

    var body: some View {
        Form {
            ForEach(registry.modules, id: \.id) { module in
                HStack {
                    Image(systemName: module.icon)
                    Text(module.displayName)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { module.isEnabled },
                        set: { newValue in
                            if newValue {
                                registry.enableModule(module.id)
                            } else {
                                registry.disableModule(module.id)
                            }
                        }
                    ))
                }
            }
        }
        .padding()
    }
}
