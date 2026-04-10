import Combine
import Foundation
import Network
import SystemConfiguration
import UserNotifications
import os

struct InterfaceInfo: Identifiable {
    let id: String
    let name: String
    let ip: String
    let type: InterfaceType

    enum InterfaceType: String {
        case wifi = "WiFi"
        case ethernet = "Ethernet"
        case vpn = "VPN"
        case other = "Other"
    }
}

struct PingResult: Identifiable {
    let id: String
    let host: String
    var latencyMs: Double?
    var isReachable: Bool

    init(host: String) {
        self.id = host
        self.host = host
        self.latencyMs = nil
        self.isReachable = false
    }
}

struct AppNetworkUsage: Identifiable {
    let id: String
    let name: String
    let sendRate: Double   // bytes per second
    let recvRate: Double   // bytes per second
    var totalRate: Double { sendRate + recvRate }
}

@MainActor
final class NetworkViewModel: ObservableObject {
    // MARK: - Speed monitoring
    @Published var uploadSpeed: Double = 0
    @Published var downloadSpeed: Double = 0
    @Published var sessionBytesIn: UInt64 = 0
    @Published var sessionBytesOut: UInt64 = 0
    @Published var uploadHistory: [Double] = []
    @Published var downloadHistory: [Double] = []

    // MARK: - Interface & IP
    @Published var activeInterface: String = "—"
    @Published var localIP: String = "—"
    @Published var publicIP: String = "Fetching..."
    @Published var interfaces: [InterfaceInfo] = []
    @Published var hasVPN: Bool = false

    // MARK: - Connectivity
    @Published var isOnline: Bool = true
    @Published var pingResults: [PingResult] = []

    // MARK: - Top apps
    @Published var topApps: [AppNetworkUsage] = []

    // MARK: - DNS
    @Published var dnsServers: [String] = []
    @Published var dnsQuery: String = ""
    @Published var dnsResults: [String] = []
    @Published var isDNSLoading: Bool = false

    // MARK: - Private
    private let dataSource = NetworkDataSource()
    private let settings = BrewbarSettings.shared
    private var speedTimer: Timer?
    private var previousSnapshot: NetworkDataSource.Snapshot?
    private var initialBytesIn: UInt64 = 0
    private var initialBytesOut: UInt64 = 0
    private let historySize = 60
    private let monitor = NWPathMonitor()
    private var lastBandwidthAlertTime: Date?

    // MARK: - Lifecycle

    func start() {
        let snapshot = dataSource.readStats()
        initialBytesIn = snapshot.totalBytesIn
        initialBytesOut = snapshot.totalBytesOut
        previousSnapshot = snapshot
        updateActiveInterface(from: snapshot)

        startNetworkMonitor()
        fetchPublicIP()
        refreshInterfaces()
        refreshDNSServers()
        scheduleTimer()
    }

    func stop() {
        speedTimer?.invalidate()
        speedTimer = nil
        monitor.cancel()
    }

    func scheduleTimer() {
        speedTimer?.invalidate()
        speedTimer = Timer.scheduledTimer(withTimeInterval: settings.networkUpdateInterval, repeats: true) { @Sendable [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollSpeed()
            }
        }
    }

    /// Called when the dropdown opens — runs pings and refreshes on demand.
    func refreshAll() {
        refreshInterfaces()
        runPings()
        refreshTopApps()
    }

    // MARK: - Speed polling

    private func pollSpeed() {
        let current = dataSource.readStats()
        defer { previousSnapshot = current }

        guard let previous = previousSnapshot else { return }

        let elapsed = current.timestamp.timeIntervalSince(previous.timestamp)
        guard elapsed > 0 else { return }

        let deltaIn = current.totalBytesIn >= previous.totalBytesIn
            ? current.totalBytesIn - previous.totalBytesIn : 0
        let deltaOut = current.totalBytesOut >= previous.totalBytesOut
            ? current.totalBytesOut - previous.totalBytesOut : 0

        downloadSpeed = Double(deltaIn) / elapsed
        uploadSpeed = Double(deltaOut) / elapsed

        sessionBytesIn = current.totalBytesIn - initialBytesIn
        sessionBytesOut = current.totalBytesOut - initialBytesOut

        downloadHistory.append(downloadSpeed)
        uploadHistory.append(uploadSpeed)
        if downloadHistory.count > historySize {
            downloadHistory.removeFirst(downloadHistory.count - historySize)
        }
        if uploadHistory.count > historySize {
            uploadHistory.removeFirst(uploadHistory.count - historySize)
        }

        updateActiveInterface(from: current)
        checkBandwidthAlert()
    }

    // MARK: - Connectivity

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { @Sendable [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOnline = self.isOnline
                self.isOnline = path.status == .satisfied
                // Refresh interfaces and public IP only when network state actually changes
                if self.isOnline != wasOnline || self.publicIP == "Fetching..." {
                    self.refreshInterfaces()
                    self.refreshDNSServers()
                    self.fetchPublicIP()
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.brewbar.network-monitor"))
    }

    private func refreshInterfaces() {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrs) == 0, let first = ifaddrs else { return }
        defer { freeifaddrs(ifaddrs) }

        var seen = Set<String>()
        var result: [InterfaceInfo] = []
        var vpnDetected = false

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let addr = ptr.pointee
            let family = addr.ifa_addr.pointee.sa_family
            guard family == UInt8(AF_INET) else { continue }

            let name = String(cString: addr.ifa_name)
            guard !seen.contains(name), name != "lo0" else { continue }
            seen.insert(name)

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(addr.ifa_addr, socklen_t(addr.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
            let ip = String(cString: hostname)

            let type: InterfaceInfo.InterfaceType
            if name.hasPrefix("utun") || name.hasPrefix("ipsec") || name.hasPrefix("ppp") {
                type = .vpn
                vpnDetected = true
            } else if name.hasPrefix("en0") {
                type = .wifi
            } else if name.hasPrefix("en") {
                type = .ethernet
            } else {
                type = .other
            }

            result.append(InterfaceInfo(id: name, name: name, ip: ip, type: type))
        }

        interfaces = result
        hasVPN = vpnDetected
    }

    private func updateActiveInterface(from snapshot: NetworkDataSource.Snapshot) {
        if let primary = dataSource.primaryInterface(from: snapshot) ?? dataSource.activeInterface(from: snapshot) {
            activeInterface = primary.name
        }
        localIP = getLocalIP() ?? "—"
    }

    // MARK: - Public IP

    private func fetchPublicIP() {
        Task {
            guard let url = URL(string: "https://api.ipify.org") else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let ip = String(data: data, encoding: .utf8) {
                    self.publicIP = ip
                }
            } catch {
                self.publicIP = "Unavailable"
            }
        }
    }

    // MARK: - Ping

    private func runPings() {
        var results: [PingResult] = []
        for host in settings.pingHosts {
            results.append(PingResult(host: host))
        }
        pingResults = results

        for (index, host) in settings.pingHosts.enumerated() {
            Task {
                let latency = await Self.ping(host: host)
                guard index < pingResults.count else { return }
                pingResults[index].latencyMs = latency
                pingResults[index].isReachable = latency != nil
            }
        }
    }

    private static func ping(host: String) async -> Double? {
        let start = CFAbsoluteTimeGetCurrent()

        return await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "com.brewbar.ping.\(host)")
            let connection = NWConnection(host: NWEndpoint.Host(host), port: 80, using: .tcp)
            let resumed = OSAllocatedUnfairLock(initialState: false)

            let timeout = DispatchWorkItem {
                let alreadyResumed = resumed.withLock { val -> Bool in
                    if val { return true }
                    val = true
                    return false
                }
                guard !alreadyResumed else { return }
                connection.cancel()
                continuation.resume(returning: nil)
            }
            queue.asyncAfter(deadline: .now() + 3, execute: timeout)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let alreadyResumed = resumed.withLock { val -> Bool in
                        if val { return true }
                        val = true
                        return false
                    }
                    guard !alreadyResumed else { return }
                    timeout.cancel()
                    connection.cancel()
                    let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                    continuation.resume(returning: elapsed)
                case .failed, .cancelled:
                    let alreadyResumed = resumed.withLock { val -> Bool in
                        if val { return true }
                        val = true
                        return false
                    }
                    guard !alreadyResumed else { return }
                    timeout.cancel()
                    continuation.resume(returning: nil)
                default:
                    break
                }
            }
            connection.start(queue: queue)
        }
    }

    // MARK: - Top Apps

    private func refreshTopApps() {
        Task.detached {
            let apps = Self.fetchTopApps(count: 5)
            await MainActor.run { [weak self] in
                self?.topApps = apps
            }
        }
    }

    // System daemons to filter out — not user-facing apps
    private static let systemProcesses: Set<String> = [
        "launchd", "mDNSResponder", "symptomsd", "airportd", "wifip2pd",
        "wifianalyticsd", "rapportd", "replicatord", "sharingd", "netbiosd",
        "apsd", "identityservice", "CommCenter", "trustd", "cloudd",
        "nsurlsessiond", "networkserviceproxy", "remoted", "remotepairingd",
        "remindd", "routined", "dasd", "timed", "locationd", "configd",
        "UserEventAgent", "SystemUIServer", "WindowServer", "kernel_task",
        "coreaudiod", "audioclocksyncd", "powerd", "distnoted",
        "bluetoothd", "bluetoothaudiod", "ControlCenter", "Dock",
        "Finder", "loginwindow", "coreduetd", "duetexpertd",
        "analyticsd", "diagnosticd", "syslogd", "notifyd",
        "AMPDeviceDiscoveryAgent", "AMPLibraryAgent", "akd",
        "lsd", "diskarbitrationd", "fseventsd", "revisiond",
        "mediaremoted", "contextstored", "containermanagerd",
        "filecoordinationd", "iconservicesagent",
    ]

    nonisolated private static func fetchTopApps(count: Int) -> [AppNetworkUsage] {
        // Take two snapshots 1 second apart to compute live rates
        guard let snap1 = nettopSnapshot() else { return [] }
        Thread.sleep(forTimeInterval: 1)
        guard let snap2 = nettopSnapshot() else { return [] }

        var apps: [String: (sendRate: Double, recvRate: Double)] = [:]

        for (name, s2) in snap2 {
            let s1 = snap1[name] ?? (0, 0)
            let deltaIn = s2.bytesIn >= s1.bytesIn ? Double(s2.bytesIn - s1.bytesIn) : 0
            let deltaOut = s2.bytesOut >= s1.bytesOut ? Double(s2.bytesOut - s1.bytesOut) : 0
            guard deltaIn + deltaOut > 0 else { continue }
            apps[name] = (sendRate: deltaOut, recvRate: deltaIn)
        }

        return apps
            .map { AppNetworkUsage(id: $0.key, name: $0.key, sendRate: $0.value.sendRate, recvRate: $0.value.recvRate) }
            .sorted { $0.totalRate > $1.totalRate }
            .prefix(count)
            .map { $0 }
    }

    nonisolated private static func nettopSnapshot() -> [String: (bytesIn: UInt64, bytesOut: UInt64)]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
        process.arguments = ["-P", "-L", "1", "-n", "-J", "bytes_in,bytes_out"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        var apps: [String: (bytesIn: UInt64, bytesOut: UInt64)] = [:]

        for line in output.components(separatedBy: "\n").dropFirst() {
            let parts = line.components(separatedBy: ",")
            guard parts.count >= 3 else { continue }

            let rawName = parts[0].trimmingCharacters(in: .whitespaces)
            guard !rawName.isEmpty else { continue }

            // Strip PID suffix: "Chrome.12345" → "Chrome"
            let name: String
            if let dotRange = rawName.range(of: ".", options: .backwards),
               rawName[dotRange.upperBound...].allSatisfy(\.isNumber) {
                name = String(rawName[..<dotRange.lowerBound])
            } else {
                name = rawName
            }

            guard !systemProcesses.contains(name) else { continue }

            let bytesIn = UInt64(parts[1]) ?? 0
            let bytesOut = UInt64(parts[2]) ?? 0

            let existing = apps[name] ?? (0, 0)
            apps[name] = (existing.bytesIn + bytesIn, existing.bytesOut + bytesOut)
        }

        return apps
    }

    // MARK: - DNS

    private func refreshDNSServers() {
        guard let store = SCDynamicStoreCreate(nil, "Brewbar" as CFString, nil, nil) else { return }
        guard let state = SCDynamicStoreCopyValue(store, "State:/Network/Global/DNS" as CFString) as? [String: Any] else { return }
        guard let addresses = state["ServerAddresses"] as? [String] else { return }
        dnsServers = addresses
    }

    func resolveDNS() {
        let query = dnsQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isDNSLoading = true
        dnsResults = []

        Task {
            let host = CFHostCreateWithName(nil, query as CFString).takeRetainedValue()
            var resolved = DarwinBoolean(false)
            CFHostStartInfoResolution(host, .addresses, nil)
            guard let addresses = CFHostGetAddressing(host, &resolved)?.takeUnretainedValue() as? [Data] else {
                self.dnsResults = ["Resolution failed"]
                self.isDNSLoading = false
                return
            }

            var results: [String] = []
            for addressData in addresses {
                addressData.withUnsafeBytes { ptr in
                    guard let sockaddr = ptr.baseAddress?.assumingMemoryBound(to: sockaddr.self) else { return }
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(sockaddr, socklen_t(addressData.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        results.append(String(cString: hostname))
                    }
                }
            }

            self.dnsResults = results.isEmpty ? ["No results"] : results
            self.isDNSLoading = false
        }
    }

    // MARK: - Bandwidth Alert

    private func checkBandwidthAlert() {
        let thresholdBytes = settings.networkBandwidthAlertThreshold * 1_000_000 / 8
        guard downloadSpeed > thresholdBytes || uploadSpeed > thresholdBytes else { return }
        // Don't spam — at most one alert per 60 seconds
        if let last = lastBandwidthAlertTime, Date().timeIntervalSince(last) < 60 { return }
        lastBandwidthAlertTime = Date()
        sendBandwidthAlert()
    }

    private func sendBandwidthAlert() {
        let content = UNMutableNotificationContent()
        content.title = "Brewbar: High Bandwidth"
        content.body = "Network speed exceeded \(formatSpeed(settings.networkBandwidthAlertThreshold * 1_000_000 / 8))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "bandwidth-alert-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Helpers

    private func getLocalIP() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let addr = ptr.pointee
            let family = addr.ifa_addr.pointee.sa_family
            guard family == UInt8(AF_INET) else { continue }

            let name = String(cString: addr.ifa_name)
            guard name == "en0" || name == "en1" else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
                addr.ifa_addr, socklen_t(addr.ifa_addr.pointee.sa_len),
                &hostname, socklen_t(hostname.count),
                nil, 0, NI_NUMERICHOST
            ) == 0 {
                return String(cString: hostname)
            }
        }
        return nil
    }
}

// MARK: - Formatting

func formatSpeed(_ bytesPerSecond: Double, unit: NetworkDisplayUnit = .auto) -> String {
    let bitsPerSecond = bytesPerSecond * 8
    switch unit {
    case .kbps:
        return String(format: "%.0f Kbps", bitsPerSecond / 1_000)
    case .mbps:
        return String(format: "%.1f Mbps", bitsPerSecond / 1_000_000)
    case .auto:
        if bitsPerSecond < 1_000_000 {
            return String(format: "%.0f Kbps", bitsPerSecond / 1_000)
        } else if bitsPerSecond < 1_000_000_000 {
            return String(format: "%.1f Mbps", bitsPerSecond / 1_000_000)
        } else {
            return String(format: "%.2f Gbps", bitsPerSecond / 1_000_000_000)
        }
    }
}

func formatBytes(_ bytes: UInt64) -> String {
    let b = Double(bytes)
    if b < 1_000 {
        return "\(bytes) B"
    } else if b < 1_000_000 {
        return String(format: "%.1f KB", b / 1_000)
    } else if b < 1_000_000_000 {
        return String(format: "%.1f MB", b / 1_000_000)
    } else {
        return String(format: "%.2f GB", b / 1_000_000_000)
    }
}
