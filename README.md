<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue?style=flat-square&logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/swift-5.10-orange?style=flat-square&logo=swift" alt="Swift 5.10">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/github/v/release/mzelzoghbi/brewbar?style=flat-square&label=release" alt="Latest Release">
  <img src="https://img.shields.io/github/actions/workflow/status/mzelzoghbi/brewbar/build.yml?style=flat-square&label=build" alt="Build Status">
  <img src="https://img.shields.io/badge/homebrew-tap-important?style=flat-square&logo=homebrew" alt="Homebrew">
</p>

<h1 align="center">Brewbar</h1>

<p align="center">
  <strong>A native macOS menu bar developer toolkit.</strong><br>
  Live network speeds, color picker, IP info, ping, DNS — one click away, always visible.
</p>

<p align="center">
  <code>brew tap mzelzoghbi/brewbar && brew install --cask brewbar</code>
</p>

---

## What's Inside

### Network Module

Everything network in one unified panel:

- **Live Speeds** — Upload/download in Kbps, Mbps, or Gbps with configurable update interval
- **Traffic Chart** — Bar chart history of the last 60 data points
- **Active Apps** — Top 5 apps using your network right now with live send/receive rates
- **Online/Offline** — Real-time connectivity status via NWPathMonitor
- **VPN Detection** — Automatically detects active VPN connections
- **Public & Local IP** — One-click copy, refreshes on network change
- **Interfaces** — All active interfaces (WiFi, Ethernet, VPN) with IPs
- **Ping Latency** — TCP ping to configurable hosts (default: 8.8.8.8, 1.1.1.1)
- **DNS Servers** — Shows your currently configured DNS servers
- **DNS Lookup** — Resolve any domain to its IP addresses
- **Session Stats** — Total bytes sent/received since launch
- **Bandwidth Alerts** — Notification when speed exceeds your threshold

### Color Picker

- **Screen Sampler** — Click the eyedropper in the menu bar to pick any color from your screen
- **All Formats** — HEX, RGB, RGBA, HSL, SwiftUI, UIKit — each with a copy button
- **History** — Last 5 picked colors as clickable swatches
- **Auto Popup** — Pick a color and the panel opens automatically with all values

## Installation

### Homebrew (recommended)

```bash
brew tap mzelzoghbi/brewbar
brew install --cask brewbar
```

### Manual

Download the latest `.dmg` from [Releases](https://github.com/mzelzoghbi/brewbar/releases).

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel

## Building from Source

```bash
git clone https://github.com/mzelzoghbi/brewbar
cd brewbar
brew install xcodegen
xcodegen generate
open Brewbar.xcodeproj
```

Or build from the command line:

```bash
xcodegen generate
xcodebuild -project Brewbar.xcodeproj -scheme Brewbar build
```

## Settings

Open **Settings** from the popover footer to configure:

| Setting | Options |
|---------|---------|
| Launch at Login | On/Off |
| Update Interval | 1s, 5s, 10s, 20s, 30s |
| Display Unit | Auto, Kbps, Mbps |
| Show Upload/Download | Toggle each independently |
| Vertical Layout | Stack speeds in a column |
| Bandwidth Alert | Threshold in Mbps |

## Architecture

Modular design — every feature is a self-contained module conforming to the `BrewbarModule` protocol. Modules are registered at launch and managed by the `ModuleRegistry`.

```
Brewbar/
├── App/            # AppDelegate, ModuleRegistry, BrewbarApp
├── Core/           # BrewbarModule protocol, Settings, Keychain
├── Modules/
│   ├── Network/    # Speeds, IP, ping, DNS, interfaces, top apps
│   └── ColorPicker/# Screen sampler, format converter, history
├── UI/             # PopoverContentView, MenuBarContentView, SettingsView
└── Resources/      # Assets, entitlements, Info.plist
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Battery Optimized

Brewbar is designed to be light on resources:

- **Speed polling** — Only timer running, at your chosen interval
- **Pings** — Only run when you open the dropdown, not in background
- **Interfaces & IP** — Refresh on network change events, not polling
- **Top Apps** — Measured on-demand when dropdown opens
- **Color Picker** — Zero background work, only active when you pick

## Roadmap

| Version | Features |
|---------|----------|
| **v0.1** | Network Module + Color Picker |
| v0.2 | Active Ports + Clipboard History |
| v0.3 | Encoder/Decoder + Environment Switcher |
| v1.0 | Plugin system + stable release |

## Contributing

Contributions welcome! See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

## License

[MIT](LICENSE) — Crafted with love by Zak in Egypt.
