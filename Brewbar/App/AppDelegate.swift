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

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerModules()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        registry.stopAll()
    }

    private func registerModules() {
        let networkMonitor = NetworkMonitorModule(contextEngine: contextEngine)
        let ipConnectivity = IPConnectivityModule(contextEngine: contextEngine)

        registry.register(networkMonitor)
        registry.register(ipConnectivity)
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

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
