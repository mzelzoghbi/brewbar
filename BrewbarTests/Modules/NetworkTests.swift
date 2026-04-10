import XCTest

@testable import Brewbar

final class NetworkTests: XCTestCase {

    func testNetworkDataSourceReturnsSnapshot() {
        let dataSource = NetworkDataSource()
        let snapshot = dataSource.readStats()

        XCTAssertFalse(snapshot.interfaces.isEmpty, "Expected at least one network interface")
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
        XCTAssertEqual(formatSpeed(500), "4 Kbps")
        XCTAssertEqual(formatSpeed(0), "0 Kbps")
        XCTAssertEqual(formatSpeed(1_500), "12 Kbps")
        XCTAssertEqual(formatSpeed(1_500_000), "12.0 Mbps")
        XCTAssertEqual(formatSpeed(1_500_000_000), "12.00 Gbps")
    }

    func testFormatSpeedFixedUnit() {
        XCTAssertEqual(formatSpeed(1_500_000, unit: .kbps), "12000 Kbps")
        XCTAssertEqual(formatSpeed(1_500_000, unit: .mbps), "12.0 Mbps")
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
        Thread.sleep(forTimeInterval: 0.1)
        let snap2 = dataSource.readStats()

        XCTAssertGreaterThanOrEqual(snap2.totalBytesIn, snap1.totalBytesIn)
        XCTAssertGreaterThanOrEqual(snap2.totalBytesOut, snap1.totalBytesOut)
    }

    @MainActor
    func testViewModelInitialState() {
        let vm = NetworkViewModel()
        XCTAssertTrue(vm.isOnline)
        XCTAssertEqual(vm.publicIP, "Fetching...")
        XCTAssertTrue(vm.interfaces.isEmpty)
        XCTAssertFalse(vm.hasVPN)
        XCTAssertEqual(vm.uploadSpeed, 0)
        XCTAssertEqual(vm.downloadSpeed, 0)
    }

    @MainActor
    func testViewModelStartPopulatesInterfaces() async {
        let vm = NetworkViewModel()
        vm.start()
        try? await Task.sleep(for: .seconds(1))

        XCTAssertFalse(vm.interfaces.isEmpty, "Expected at least one interface after start")
        vm.stop()
    }
}
