import Combine
import Foundation
import UserNotifications

@MainActor
final class NetworkMonitorViewModel: ObservableObject {
    @Published var uploadSpeed: Double = 0        // bytes per second
    @Published var downloadSpeed: Double = 0      // bytes per second
    @Published var activeInterface: String = "—"
    @Published var localIP: String = "—"
    @Published var publicIP: String = "Fetching..."
    @Published var sessionBytesIn: UInt64 = 0
    @Published var sessionBytesOut: UInt64 = 0
    @Published var uploadHistory: [Double] = []   // last 60 data points
    @Published var downloadHistory: [Double] = [] // last 60 data points

    private let dataSource = NetworkDataSource()
    private let settings = BrewbarSettings.shared
    private var timer: Timer?
    private var previousSnapshot: NetworkDataSource.Snapshot?
    private var initialBytesIn: UInt64 = 0
    private var initialBytesOut: UInt64 = 0
    private let historySize = 60

    func start() {
        let snapshot = dataSource.readStats()
        initialBytesIn = snapshot.totalBytesIn
        initialBytesOut = snapshot.totalBytesOut
        previousSnapshot = snapshot

        updateActiveInterface(from: snapshot)
        fetchPublicIP()
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: settings.networkUpdateInterval, repeats: true) { @Sendable [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
    }

    private func poll() {
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

        // Session totals
        sessionBytesIn = current.totalBytesIn - initialBytesIn
        sessionBytesOut = current.totalBytesOut - initialBytesOut

        // History
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

    private func updateActiveInterface(from snapshot: NetworkDataSource.Snapshot) {
        if let primary = dataSource.primaryInterface(from: snapshot) ?? dataSource.activeInterface(from: snapshot) {
            activeInterface = primary.name
        }
        localIP = getLocalIP() ?? "—"
    }

    private func checkBandwidthAlert() {
        // Threshold is in Mbps, convert to bytes/s for comparison
        let thresholdBytes = settings.networkBandwidthAlertThreshold * 1_000_000 / 8
        if downloadSpeed > thresholdBytes || uploadSpeed > thresholdBytes {
            sendBandwidthAlert()
        }
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
        if bitsPerSecond < 1_000 {
            return String(format: "%.0f bps", bitsPerSecond)
        } else if bitsPerSecond < 1_000_000 {
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
