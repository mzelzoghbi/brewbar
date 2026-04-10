# Contributing to Brewbar

Thanks for your interest in contributing!

## Getting Started

1. Fork and clone the repo
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. Generate the project: `xcodegen generate`
4. Open `Brewbar.xcodeproj` in Xcode
5. Build and run (Cmd+R)

## Adding a New Module

1. Create a new directory under `Brewbar/Modules/YourModule/`
2. Create these files following the existing pattern:
   - `YourModule.swift` — conforms to `BrewbarModule`
   - `YourModuleViewModel.swift` — business logic
   - `Views/YourMenuBarView.swift` — status bar view
   - `Views/YourDropdownView.swift` — popover view
3. Register your module in `AppDelegate.swift` `registerModules()`
4. Add settings keys to `BrewbarSettings.swift` if needed
5. Add tests under `BrewbarTests/Modules/`
6. Regenerate the project: `xcodegen generate`

## Writing Tests

- Place tests in `BrewbarTests/Modules/`
- Test data sources and view models, not views directly
- Use `@MainActor` for tests that touch `@MainActor` types
- Run tests: `xcodebuild -scheme Brewbar test`

## Code Style

- Use Swift's standard naming conventions
- Use `@MainActor` for all UI-related classes
- Prefer `async/await` over completion handlers
- Keep modules self-contained — don't create cross-module dependencies

## PR Checklist

- [ ] All tests pass
- [ ] New module includes tests
- [ ] CHANGELOG.md updated
- [ ] README.md roadmap updated if adding a new module
- [ ] No hardcoded secrets or API keys

## Building a Plugin

See [PLUGINS.md](PLUGINS.md) for the plugin development guide.

## Reporting Issues

Use the GitHub issue templates for bug reports and feature requests.
