import SwiftUI

struct NetworkMenuBarView: View {
    @ObservedObject var viewModel: NetworkMonitorViewModel

    private let settings = BrewbarSettings.shared

    var body: some View {
        HStack(spacing: 4) {
            if settings.networkShowUpload {
                HStack(spacing: 2) {
                    Text("↑")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(formatSpeed(viewModel.uploadSpeed, unit: settings.networkDisplayUnit))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
            }

            if settings.networkShowDownload {
                HStack(spacing: 2) {
                    Text("↓")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(formatSpeed(viewModel.downloadSpeed, unit: settings.networkDisplayUnit))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
            }
        }
    }
}
