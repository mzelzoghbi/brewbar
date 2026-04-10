import Foundation

/// Centralized settings wrapper around UserDefaults.
final class BrewbarSettings: ObservableObject {
    static let shared = BrewbarSettings()

    private let defaults = UserDefaults.standard

    // MARK: - General

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") }
    }

    // MARK: - Network Monitor

    @Published var networkUpdateInterval: TimeInterval {
        didSet { defaults.set(networkUpdateInterval, forKey: "networkUpdateInterval") }
    }

    @Published var networkDisplayUnit: NetworkDisplayUnit {
        didSet { defaults.set(networkDisplayUnit.rawValue, forKey: "networkDisplayUnit") }
    }

    @Published var networkShowUpload: Bool {
        didSet { defaults.set(networkShowUpload, forKey: "networkShowUpload") }
    }

    @Published var networkShowDownload: Bool {
        didSet { defaults.set(networkShowDownload, forKey: "networkShowDownload") }
    }

    @Published var networkBandwidthAlertThreshold: Double {
        didSet { defaults.set(networkBandwidthAlertThreshold, forKey: "networkBandwidthAlertThreshold") }
    }

    // MARK: - IP & Connectivity

    @Published var pingHosts: [String] {
        didSet { defaults.set(pingHosts, forKey: "pingHosts") }
    }

    // MARK: - Module Enable/Disable

    func isModuleEnabled(_ moduleId: String) -> Bool {
        let key = "module.\(moduleId).enabled"
        if defaults.object(forKey: key) == nil {
            return true // enabled by default
        }
        return defaults.bool(forKey: key)
    }

    func setModuleEnabled(_ moduleId: String, enabled: Bool) {
        defaults.set(enabled, forKey: "module.\(moduleId).enabled")
    }

    private init() {
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.networkUpdateInterval = defaults.object(forKey: "networkUpdateInterval") as? TimeInterval ?? 1.0
        self.networkDisplayUnit = NetworkDisplayUnit(rawValue: defaults.string(forKey: "networkDisplayUnit") ?? "auto") ?? .auto
        self.networkShowUpload = defaults.object(forKey: "networkShowUpload") as? Bool ?? true
        self.networkShowDownload = defaults.object(forKey: "networkShowDownload") as? Bool ?? true
        self.networkBandwidthAlertThreshold = defaults.object(forKey: "networkBandwidthAlertThreshold") as? Double ?? 10.0
        self.pingHosts = defaults.stringArray(forKey: "pingHosts") ?? ["8.8.8.8", "1.1.1.1"]
    }
}

enum NetworkDisplayUnit: String, CaseIterable, Identifiable {
    case auto = "auto"
    case kb = "KB"
    case mb = "MB"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .kb: return "KB/s"
        case .mb: return "MB/s"
        }
    }
}
