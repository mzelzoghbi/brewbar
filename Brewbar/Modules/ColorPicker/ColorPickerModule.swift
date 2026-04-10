import SwiftUI

@MainActor
final class ColorPickerModule: BrewbarModule, ObservableObject {
    let id = "color-picker"
    let displayName = "Color Picker"
    let icon = "eyedropper"
    @Published var isEnabled: Bool = true

    let viewModel = ColorPickerViewModel()

    init(contextEngine: ContextEngine) {}

    var menuBarView: AnyView {
        AnyView(ColorPickerMenuBarView(viewModel: viewModel))
    }

    var dropdownView: AnyView {
        AnyView(ColorPickerDropdownView(viewModel: viewModel))
    }

    func start() {}
    func stop() {}
}
