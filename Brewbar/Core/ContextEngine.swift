import AppKit
import Combine
import Foundation

enum ProjectType: String, CaseIterable {
    case nodejs = "Node.js"
    case xcode = "Xcode"
    case docker = "Docker"
    case python = "Python"
    case rust = "Rust"
    case unknown = "Unknown"
}

@MainActor
final class ContextEngine: ObservableObject {
    @Published var activeApp: String = ""
    @Published var activeProjectPath: URL? = nil
    @Published var detectedProjectType: ProjectType = .unknown

    private var cancellables = Set<AnyCancellable>()

    init() {
        observeActiveApp()
    }

    private func observeActiveApp() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { notification -> String? in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                    return nil
                }
                return app.localizedName
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$activeApp)
    }

    func detectProjectType(at url: URL) -> ProjectType {
        let fm = FileManager.default
        let path = url.path

        if fm.fileExists(atPath: (path as NSString).appendingPathComponent("package.json")) {
            return .nodejs
        }
        if fm.fileExists(atPath: (path as NSString).appendingPathComponent("Cargo.toml")) {
            return .rust
        }
        if fm.fileExists(atPath: (path as NSString).appendingPathComponent("docker-compose.yml")) ||
           fm.fileExists(atPath: (path as NSString).appendingPathComponent("docker-compose.yaml")) {
            return .docker
        }
        if fm.fileExists(atPath: (path as NSString).appendingPathComponent("requirements.txt")) ||
           fm.fileExists(atPath: (path as NSString).appendingPathComponent("pyproject.toml")) {
            return .python
        }

        // Check for .xcodeproj
        if let contents = try? fm.contentsOfDirectory(atPath: path) {
            if contents.contains(where: { $0.hasSuffix(".xcodeproj") || $0.hasSuffix(".xcworkspace") }) {
                return .xcode
            }
        }

        return .unknown
    }

    func updateProjectPath(_ url: URL?) {
        activeProjectPath = url
        if let url {
            detectedProjectType = detectProjectType(at: url)
        } else {
            detectedProjectType = .unknown
        }
    }
}
