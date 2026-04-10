import SwiftUI

@MainActor
final class NetworkModule: BrewbarModule, ObservableObject {
    let id = "network"
    let displayName = "Network"
    let icon = "network"
    @Published var isEnabled: Bool = true

    let viewModel = NetworkViewModel()

    init(contextEngine: ContextEngine) {}

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
