# Brewbar Architecture

## Overview

Brewbar is built as a native macOS menu bar application using Swift and SwiftUI. Every feature is a self-contained **module** that conforms to the `BrewbarModule` protocol.

## Core Components

### BrewbarModule Protocol
The foundation of the entire system. Every feature — built-in or plugin — conforms to this protocol:

```swift
public protocol BrewbarModule: AnyObject, Identifiable, ObservableObject {
    var id: String { get }
    var displayName: String { get }
    var icon: String { get }
    var isEnabled: Bool { get set }
    var menuBarView: AnyView { get }
    var dropdownView: AnyView { get }
    func start()
    func stop()
}
```

- `menuBarView`: Rendered in the status bar area
- `dropdownView`: Rendered in the popover when the user clicks the status item
- `start()` / `stop()`: Lifecycle management for polling, observing, etc.

### ModuleRegistry
Singleton that manages all registered modules. Modules are registered at app launch and can be enabled/disabled at runtime via Settings.

### ContextEngine
Observes the active application and working directory. Modules receive the context engine via dependency injection and can adapt their behavior based on what the user is currently doing.

### AppDelegate
Sets up the `NSStatusItem`, manages the `NSPopover`, and orchestrates module registration.

## Module Architecture

Each module follows MVVM:

```
Module/
├── [Name]Module.swift           ← Conforms to BrewbarModule
├── [Name]ViewModel.swift        ← Business logic, @Published state
└── Views/
    ├── [Name]MenuBarView.swift  ← Compact status bar view
    └── [Name]DropdownView.swift ← Full popover view
```

### Network Monitor
Uses `sysctl` with `NET_RT_IFLIST2` to read per-interface byte counts. Calculates speed by computing deltas between polls. This is the most efficient approach — no subprocess spawning, no `nettop`, no `getifaddrs`.

### IP & Connectivity
Uses `getifaddrs` for interface enumeration, `NWPathMonitor` for online/offline detection, `NWConnection` for TCP-based latency measurement, and `CFHost` for DNS resolution.

## Data Flow

```
sysctl/Network APIs → ViewModel (@Published) → SwiftUI Views
                              ↑
                    BrewbarSettings (UserDefaults)
                              ↑
                       ContextEngine
```

## Settings
All user preferences are stored in `UserDefaults` via `BrewbarSettings`. Sensitive data (API keys, secrets) uses `KeychainManager` which wraps macOS Keychain (`Security` framework).

## Threading
- All UI updates use `@MainActor`
- Network polling runs on background `DispatchQueue` / `Timer`
- `sysctl` calls are synchronous but fast (~0.1ms)
