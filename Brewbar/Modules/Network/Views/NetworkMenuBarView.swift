import SwiftUI

struct NetworkMenuBarView: View {
    @ObservedObject var viewModel: NetworkViewModel
    @ObservedObject private var settings = BrewbarSettings.shared

    var body: some View {
        HStack(spacing: 6) {
            // Online/VPN indicator
            Circle()
                .fill(viewModel.isOnline ? Color.green : Color.red)
                .frame(width: 6, height: 6)

            if viewModel.hasVPN {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.blue)
            }

            // Speed display
            if settings.networkLayoutVertical {
                verticalSpeeds
            } else {
                horizontalSpeeds
            }
        }
    }

    private var horizontalSpeeds: some View {
        HStack(spacing: 6) {
            if settings.networkShowUpload {
                speedLabel(arrow: "arrow.up", speed: viewModel.uploadSpeed, color: .orange)
            }
            if settings.networkShowDownload {
                speedLabel(arrow: "arrow.down", speed: viewModel.downloadSpeed, color: .cyan)
            }
        }
    }

    private var verticalSpeeds: some View {
        VStack(alignment: .leading, spacing: 0) {
            if settings.networkShowUpload {
                speedLabel(arrow: "arrow.up", speed: viewModel.uploadSpeed, color: .orange)
            }
            if settings.networkShowDownload {
                speedLabel(arrow: "arrow.down", speed: viewModel.downloadSpeed, color: .cyan)
            }
        }
    }

    private func speedLabel(arrow: String, speed: Double, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: arrow)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
            Text(formatSpeed(speed, unit: settings.networkDisplayUnit))
                .font(.system(size: settings.networkLayoutVertical ? 9 : 12, weight: .medium, design: .monospaced))
                .frame(minWidth: settings.networkLayoutVertical ? 58 : 72, alignment: .leading)
        }
    }
}
