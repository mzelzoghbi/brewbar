import XCTest

@testable import Brewbar

final class IPConnectivityTests: XCTestCase {

    @MainActor
    func testViewModelInitialState() {
        let vm = IPConnectivityViewModel()
        XCTAssertTrue(vm.isOnline)
        XCTAssertEqual(vm.publicIP, "Fetching...")
        XCTAssertTrue(vm.interfaces.isEmpty)
        XCTAssertFalse(vm.hasVPN)
    }

    @MainActor
    func testViewModelStartPopulatesInterfaces() async {
        let vm = IPConnectivityViewModel()
        vm.start()

        // Give it a moment to enumerate interfaces
        try? await Task.sleep(for: .seconds(1))

        XCTAssertFalse(vm.interfaces.isEmpty, "Expected at least one interface after start")
        vm.stop()
    }
}
