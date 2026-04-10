import Charts
import SwiftUI

struct NetworkDropdownView: View {
    @ObservedObject var viewModel: NetworkMonitorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Live speeds
                HStack(spacing: 20) {
                    SpeedCard(label: "Upload", value: formatSpeed(viewModel.uploadSpeed), arrow: "↑", color: .blue)
                    SpeedCard(label: "Download", value: formatSpeed(viewModel.downloadSpeed), arrow: "↓", color: .green)
                }

                Divider()

                // Traffic bar chart
                VStack(alignment: .leading, spacing: 4) {
                    Text("Traffic History")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Chart {
                        ForEach(Array(viewModel.downloadHistory.enumerated()), id: \.offset) { index, value in
                            BarMark(
                                x: .value("Time", index),
                                y: .value("Speed", value * 8 / 1_000_000)
                            )
                            .foregroundStyle(Color.green.opacity(0.7))
                        }
                        ForEach(Array(viewModel.uploadHistory.enumerated()), id: \.offset) { index, value in
                            BarMark(
                                x: .value("Time", index),
                                y: .value("Speed", value * 8 / 1_000_000)
                            )
                            .foregroundStyle(Color.blue.opacity(0.7))
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v)) Mbps")
                                        .font(.system(size: 8))
                                }
                            }
                        }
                    }
                    .frame(height: 80)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 10, height: 10)
                            Text("Upload")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.green.opacity(0.7))
                                .frame(width: 10, height: 10)
                            Text("Download")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // Interface info
                InfoRow(label: "Interface", value: viewModel.activeInterface)
                InfoRow(label: "Local IP", value: viewModel.localIP)

                HStack {
                    Text("Public IP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.publicIP)
                        .font(.system(.caption, design: .monospaced))
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(viewModel.publicIP, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Session totals
                InfoRow(label: "Session Sent", value: formatBytes(viewModel.sessionBytesOut))
                InfoRow(label: "Session Received", value: formatBytes(viewModel.sessionBytesIn))

                Divider()

                // Open Activity Monitor
                Button(action: {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                }) {
                    Label("Open Activity Monitor", systemImage: "gauge.with.dots.needle.bottom.50percent")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
    }
}

struct SpeedCard: View {
    let label: String
    let value: String
    let arrow: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Text(arrow)
                    .foregroundColor(color)
                Text(label)
                    .foregroundColor(.secondary)
            }
            .font(.caption)

            Text(value)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
        }
    }
}
