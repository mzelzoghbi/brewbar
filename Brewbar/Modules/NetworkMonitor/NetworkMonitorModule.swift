import SwiftUI

@MainActor
final class NetworkMonitorModule: BrewbarModule, ObservableObject {
    let id = "network-monitor"
    let displayName = "Network Monitor"
    let icon = "network"
    @Published var isEnabled: Bool = true

    let viewModel = NetworkMonitorViewModel()
    private let contextEngine: ContextEngine

    init(contextEngine: ContextEngine) {
        self.contextEngine = contextEngine
    }

    var menuBarView: AnyView {
        AnyView(NetworkMenuBarView(viewModel: viewModel))
    }

    var dropdownView: AnyView {
        AnyView(NetworkDropdownView(viewModel: viewModel))
    }

    func start() {
        viewModel.start()
    }

    func stop() {
        viewModel.stop()
    }
}
