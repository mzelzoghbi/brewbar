import Foundation
import SwiftUI

/// Singleton that manages all registered Brewbar modules.
@MainActor
final class ModuleRegistry: ObservableObject {
    static let shared = ModuleRegistry()

    @Published private(set) var modules: [any BrewbarModule] = []

    private let settings = BrewbarSettings.shared

    private init() {}

    func register(_ module: any BrewbarModule) {
        module.isEnabled = settings.isModuleEnabled(module.id)
        modules.append(module)
        if module.isEnabled {
            module.start()
        }
    }

    func enableModule(_ moduleId: String) {
        guard let module = modules.first(where: { $0.id == moduleId }) else { return }
        module.isEnabled = true
        settings.setModuleEnabled(moduleId, enabled: true)
        module.start()
    }

    func disableModule(_ moduleId: String) {
        guard let module = modules.first(where: { $0.id == moduleId }) else { return }
        module.isEnabled = false
        settings.setModuleEnabled(moduleId, enabled: false)
        module.stop()
    }

    var enabledModules: [any BrewbarModule] {
        modules.filter(\.isEnabled)
    }

    func stopAll() {
        for module in modules {
            module.stop()
        }
    }
}
