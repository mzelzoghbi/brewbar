import SwiftUI

@MainActor
final class IPConnectivityModule: BrewbarModule, ObservableObject {
    let id = "ip-connectivity"
    let displayName = "IP & Connectivity"
    let icon = "network.badge.shield.half.filled"
    @Published var isEnabled: Bool = true

    let viewModel: IPConnectivityViewModel
    private let contextEngine: ContextEngine

    init(contextEngine: ContextEngine) {
        self.contextEngine = contextEngine
        self.viewModel = IPConnectivityViewModel()
    }

    var menuBarView: AnyView {
        AnyView(IPMenuBarView(viewModel: viewModel))
    }

    var dropdownView: AnyView {
        AnyView(IPDropdownView(viewModel: viewModel))
    }

    func start() {
        viewModel.start()
    }

    func stop() {
        viewModel.stop()
    }
}
