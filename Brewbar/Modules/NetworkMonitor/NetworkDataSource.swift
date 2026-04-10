import Darwin
import Foundation

/// Reads per-interface network byte counts using sysctl NET_RT_IFLIST2.
/// This is the most efficient approach — no subprocess, no getifaddrs overhead.
final class NetworkDataSource {
    struct InterfaceStats {
        let name: String
        let bytesIn: UInt64
        let bytesOut: UInt64
    }

    struct Snapshot {
        let timestamp: Date
        let totalBytesIn: UInt64
        let totalBytesOut: UInt64
        let interfaces: [InterfaceStats]
    }

    /// Read current byte counts from all active network interfaces via sysctl.
    func readStats() -> Snapshot {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: Int = 0

        // First call to get buffer size
        guard sysctl(&mib, UInt32(mib.count), nil, &len, nil, 0) == 0 else {
            return Snapshot(timestamp: Date(), totalBytesIn: 0, totalBytesOut: 0, interfaces: [])
        }

        var buf = [UInt8](repeating: 0, count: len)
        guard sysctl(&mib, UInt32(mib.count), &buf, &len, nil, 0) == 0 else {
            return Snapshot(timestamp: Date(), totalBytesIn: 0, totalBytesOut: 0, interfaces: [])
        }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var interfaces: [InterfaceStats] = []
        var offset = 0

        while offset < len {
            let msg = buf.withUnsafeBufferPointer { ptr -> if_msghdr in
                ptr.baseAddress!.advanced(by: offset).withMemoryRebound(to: if_msghdr.self, capacity: 1) { $0.pointee }
            }

            if Int32(msg.ifm_type) == RTM_IFINFO2 {
                let msg2 = buf.withUnsafeBufferPointer { ptr -> if_msghdr2 in
                    ptr.baseAddress!.advanced(by: offset).withMemoryRebound(to: if_msghdr2.self, capacity: 1) { $0.pointee }
                }

                let ifIndex = Int(msg2.ifm_index)
                let name = interfaceName(for: ifIndex) ?? "if\(ifIndex)"

                // Skip loopback
                if name != "lo0" {
                    let bytesIn = UInt64(msg2.ifm_data.ifi_ibytes)
                    let bytesOut = UInt64(msg2.ifm_data.ifi_obytes)

                    totalIn += bytesIn
                    totalOut += bytesOut
                    interfaces.append(InterfaceStats(name: name, bytesIn: bytesIn, bytesOut: bytesOut))
                }
            }

            offset += Int(msg.ifm_msglen)
        }

        return Snapshot(
            timestamp: Date(),
            totalBytesIn: totalIn,
            totalBytesOut: totalOut,
            interfaces: interfaces
        )
    }

    /// Derive the active interface — the one carrying the most traffic.
    func activeInterface(from snapshot: Snapshot) -> InterfaceStats? {
        snapshot.interfaces.max(by: { ($0.bytesIn + $0.bytesOut) < ($1.bytesIn + $1.bytesOut) })
    }

    private func interfaceName(for index: Int) -> String? {
        var ifr = ifreq()
        let name = if_indextoname(UInt32(index), &ifr.ifr_name.0)
        guard name != nil else { return nil }
        return withUnsafePointer(to: &ifr.ifr_name) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(IFNAMSIZ)) { cStr in
                String(cString: cStr)
            }
        }
    }
}
