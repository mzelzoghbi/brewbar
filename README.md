# Brewbar

**The first context-aware, extensible developer toolkit for the macOS menu bar.**

Live network speeds, IP info, connectivity status, and more — one click away, always visible.

<!-- Screenshot: TODO - Add screenshot/GIF of menu bar in action -->

---

## Features

| Module | Description | Status |
|--------|-------------|--------|
| Network Monitor | Live upload/download speed with sparkline graphs | Available |
| IP & Connectivity | Local/public IP, ping latency, VPN detection, DNS resolver | Available |
| Active Ports | List listening ports, one-click kill, project-aware detection | Planned |
| Clipboard History | Dev-aware clipboard with syntax detection and search | Planned |
| Encoder/Decoder | Base64, URL, JWT, hashing, JSON formatting | Planned |
| Environment Switcher | Named env configs with Keychain storage | Planned |
| Pomodoro Tracker | Focus timer with distraction detection | Planned |
| Calendar View | Mini calendar with EventKit integration | Planned |
| Prayer Times | Adhan notifications with Aladhan API | Planned |

## Installation

### Homebrew (coming soon)

```bash
brew install --cask brewbar
```

### Manual

Download the latest `.dmg` from [GitHub Releases](https://github.com/yourname/brewbar/releases).

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel

## Building from Source

```bash
git clone https://github.com/yourname/brewbar
cd brewbar
brew install xcodegen
xcodegen generate
open Brewbar.xcodeproj
# Then Cmd+R in Xcode
```

Or build from the command line:

```bash
xcodegen generate
xcodebuild -project Brewbar.xcodeproj -scheme Brewbar -configuration Debug build
```

## Architecture

Brewbar uses a modular architecture where every feature is a self-contained module conforming to the `BrewbarModule` protocol. Modules are registered at launch and can be independently enabled/disabled.

Key components:
- **BrewbarModule** — Protocol that all features implement
- **ModuleRegistry** — Singleton managing module lifecycle
- **ContextEngine** — Watches active app and project type for context-aware behavior

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Plugin Development

Third-party plugins conform to the same `BrewbarModule` protocol and are loaded from `~/.brewbar/plugins/`.

See [docs/PLUGINS.md](docs/PLUGINS.md) for the plugin development guide.

## Contributing

We welcome contributions! See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for how to get started.

Look for issues labeled `good first issue` for beginner-friendly tasks.

## Roadmap

| Version | Features |
|---------|----------|
| **v0.1** | Network Monitor + IP & Connectivity |
| v0.2 | Active Ports + Pomodoro |
| v0.3 | Clipboard History + Encoder/Decoder |
| v0.4 | Environment Switcher |
| v0.5 | Calendar View |
| v0.6 | Prayer Times |
| v1.0 | Plugin system + all 9 modules stable |
| v2.0 | AI Quick Command |

## License

[MIT](LICENSE)
