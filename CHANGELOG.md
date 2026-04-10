# Changelog

## [0.1.0] - 2026-04-10

### Added
- Initial release
- **Network Monitor**: Live upload/download speed in menu bar using sysctl
  - Auto-scaling units (B/s, KB/s, MB/s, GB/s)
  - Sparkline traffic history graph (last 60 data points)
  - Session totals (bytes sent/received)
  - Bandwidth spike alerts via notifications
  - Configurable update interval (1s/2s/5s/10s/30s)
- **IP & Connectivity**: Network interface and connectivity info
  - Local IP per interface with copy button
  - Public IP (via ipify.org) with copy button
  - Ping latency to configurable hosts (default: 8.8.8.8, 1.1.1.1)
  - VPN detection (utun/ipsec interfaces)
  - Inline DNS resolver
  - Online/offline indicator
- Module protocol system (`BrewbarModule`) for extensibility
- Context awareness engine (active app detection)
- Settings panel with per-module configuration
- Launch at login support
- GitHub Actions CI (build + test on every PR)
