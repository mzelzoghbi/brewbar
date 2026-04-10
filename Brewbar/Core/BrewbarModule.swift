import SwiftUI

/// The foundational protocol for all Brewbar features.
/// Every module — built-in or third-party plugin — must conform to this protocol.
@MainActor
public protocol BrewbarModule: AnyObject, Identifiable, ObservableObject {
    var id: String { get }
    var displayName: String { get }
    var icon: String { get }
    var isEnabled: Bool { get set }

    /// The compact view rendered in the menu bar status item area.
    @MainActor var menuBarView: AnyView { get }

    /// The full view rendered inside the dropdown popover.
    @MainActor var dropdownView: AnyView { get }

    /// Begin polling, observing, or any ongoing work.
    func start()

    /// Stop all work and release resources.
    func stop()
}

extension BrewbarModule {
    public var id: String {
        String(describing: type(of: self))
    }
}
