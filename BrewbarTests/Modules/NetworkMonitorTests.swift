import XCTest

@testable import Brewbar

final class NetworkMonitorTests: XCTestCase {

    func testNetworkDataSourceReturnsSnapshot() {
        let dataSource = NetworkDataSource()
        let snapshot = dataSource.readStats()

        // Should have at least one interface (besides loopback which we exclude)
        XCTAssertFalse(snapshot.interfaces.isEmpty, "Expected at least one network interface")

        // Total bytes should be non-zero on any machine that has ever sent data
        XCTAssertGreaterThan(snapshot.totalBytesIn, 0, "Expected non-zero bytes in")
        XCTAssertGreaterThan(snapshot.totalBytesOut, 0, "Expected non-zero bytes out")
    }

    func testActiveInterfaceSelection() {
        let dataSource = NetworkDataSource()
        let snapshot = dataSource.readStats()

        let active = dataSource.activeInterface(from: snapshot)
        XCTAssertNotNil(active, "Expected an active interface")
    }

    func testFormatSpeedAutoScaling() {
        XCTAssertEqual(formatSpeed(500), "500 B/s")
        XCTAssertEqual(formatSpeed(1_500), "1.5 KB/s")
        XCTAssertEqual(formatSpeed(1_500_000), "1.5 MB/s")
        XCTAssertEqual(formatSpeed(1_500_000_000), "1.50 GB/s")
    }

    func testFormatSpeedFixedUnit() {
        XCTAssertEqual(formatSpeed(1_500_000, unit: .kb), "1500.0 KB/s")
        XCTAssertEqual(formatSpeed(1_500_000, unit: .mb), "1.5 MB/s")
    }

    func testFormatBytes() {
        XCTAssertEqual(formatBytes(500), "500 B")
        XCTAssertEqual(formatBytes(1_500), "1.5 KB")
        XCTAssertEqual(formatBytes(1_500_000), "1.5 MB")
        XCTAssertEqual(formatBytes(1_500_000_000), "1.50 GB")
    }

    func testSnapshotDeltaCalculation() {
        let dataSource = NetworkDataSource()
        let snap1 = dataSource.readStats()

        // Small delay to ensure some bytes are transferred
        Thread.sleep(forTimeInterval: 0.1)
        let snap2 = dataSource.readStats()

        // Second snapshot should have >= first (counters are monotonically increasing)
        XCTAssertGreaterThanOrEqual(snap2.totalBytesIn, snap1.totalBytesIn)
        XCTAssertGreaterThanOrEqual(snap2.totalBytesOut, snap1.totalBytesOut)
    }
}
