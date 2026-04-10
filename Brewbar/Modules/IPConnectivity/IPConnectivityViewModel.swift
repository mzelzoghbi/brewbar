import Combine
import Foundation
import Network
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

@MainActor
final class IPConnectivityViewModel: ObservableObject {
    @Published var isOnline: Bool = true
    @Published var publicIP: String = "Fetching..."
    @Published var interfaces: [InterfaceInfo] = []
    @Published var pingResults: [PingResult] = []
    @Published var hasVPN: Bool = false
    @Published var dnsQuery: String = ""
    @Published var dnsResults: [String] = []
    @Published var isDNSLoading: Bool = false

    private let settings = BrewbarSettings.shared
    private var timer: Timer?
    private let monitor = NWPathMonitor()

    func start() {
        startNetworkMonitor()
        refreshAll()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { @Sendable [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        monitor.cancel()
    }

    func refreshAll() {
        refreshInterfaces()
        fetchPublicIP()
        runPings()
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

    // MARK: - Private

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { @Sendable [weak self] path in
            Task { @MainActor [weak self] in
                self?.isOnline = path.status == .satisfied
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
            guard family == UInt8(AF_INET) || family == UInt8(AF_INET6) else { continue }
            // Only IPv4 for simplicity in the list
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
}
