# Brewbar Plugin Development

## Overview

Brewbar plugins are Swift packages that conform to the `BrewbarModule` protocol. They are loaded at launch from `~/.brewbar/plugins/`.

## Creating a Plugin

### 1. Create the directory structure

```bash
mkdir -p ~/.brewbar/plugins/my-plugin/Sources/MyPlugin
cd ~/.brewbar/plugins/my-plugin
```

### 2. Create `Package.swift`

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyPlugin",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MyPlugin", type: .dynamic, targets: ["MyPlugin"]),
    ],
    targets: [
        .target(name: "MyPlugin"),
    ]
)
```

### 3. Create the module

```swift
// Sources/MyPlugin/MyPluginModule.swift
import SwiftUI

public final class MyPluginModule: BrewbarModule, ObservableObject {
    public let id = "my-plugin"
    public let displayName = "My Plugin"
    public let icon = "star.fill"
    @Published public var isEnabled: Bool = true

    public init() {}

    public var menuBarView: AnyView {
        AnyView(Text("*"))
    }

    public var dropdownView: AnyView {
        AnyView(Text("Hello from My Plugin!"))
    }

    public func start() {
        // Begin work
    }

    public func stop() {
        // Clean up
    }
}
```

### 4. Create the manifest

Create `brewbar-plugin.json` in your plugin root:

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "author": "Your Name",
  "minBrewbarVersion": "1.0.0",
  "entryClass": "MyPlugin.MyPluginModule"
}
```

### 5. Build and test

```bash
swift build
```

Restart Brewbar — your plugin will be discovered and loaded automatically.

## Guidelines

- Keep your plugin focused on one feature
- Handle errors gracefully — a crashing plugin should not take down Brewbar
- Use `@MainActor` for all UI-related code
- Store sensitive data using `KeychainManager`, never in plain text
- Test on both Apple Silicon and Intel if possible
