import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let registry = ModuleRegistry.shared
    private let contextEngine = ContextEngine()
    private var statusBarHostingView: NSHostingView<AnyView>?
    private var eventMonitor: Any?
    static var shared: AppDelegate?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        registerModules()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        registry.stopAll()
    }

    private func registerModules() {
        let network = NetworkModule(contextEngine: contextEngine)
        let colorPicker = ColorPickerModule(contextEngine: contextEngine)
        registry.register(network)
        registry.register(colorPicker)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menuBarContent = MenuBarContentView(registry: registry)
        let hostingView = NSHostingView(rootView: AnyView(menuBarContent))
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 22)

        if let button = statusItem.button {
            button.addSubview(hostingView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: button.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            ])
            button.action = #selector(togglePopover)
            button.target = self
        }

        statusBarHostingView = hostingView
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.animates = true

        let popoverContent = PopoverContentView(
            registry: registry,
            contextEngine: contextEngine
        )
        popover.contentViewController = NSHostingController(rootView: popoverContent)
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Brewbar Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 520, height: 320))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    func showPopover(selectingModule moduleId: String) {
        guard let button = statusItem.button else { return }

        let popoverContent = PopoverContentView(
            registry: registry,
            contextEngine: contextEngine,
            initialModuleId: moduleId
        )
        popover.contentViewController = NSHostingController(rootView: popoverContent)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Recreate content each time to pick up module enable/disable changes
            let popoverContent = PopoverContentView(
                registry: registry,
                contextEngine: contextEngine
            )
            popover.contentViewController = NSHostingController(rootView: popoverContent)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
