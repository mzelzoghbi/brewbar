import Charts
import SwiftUI

struct NetworkDropdownView: View {
    @ObservedObject var viewModel: NetworkViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Status
                HStack {
                    Circle()
                        .fill(viewModel.isOnline ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(viewModel.isOnline ? "Online" : "Offline")
                        .font(.headline)
                    Spacer()
                    if viewModel.hasVPN {
                        Label("VPN Active", systemImage: "lock.shield.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Divider()

                // Live speeds
                HStack(spacing: 20) {
                    SpeedCard(label: "Upload", value: formatSpeed(viewModel.uploadSpeed), arrow: "\u{2191}", color: .orange)
                    SpeedCard(label: "Download", value: formatSpeed(viewModel.downloadSpeed), arrow: "\u{2193}", color: .cyan)
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
                            .foregroundStyle(Color.cyan.opacity(0.7))
                        }
                        ForEach(Array(viewModel.uploadHistory.enumerated()), id: \.offset) { index, value in
                            BarMark(
                                x: .value("Time", index),
                                y: .value("Speed", value * 8 / 1_000_000)
                            )
                            .foregroundStyle(Color.orange.opacity(0.7))
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
                                .fill(Color.orange.opacity(0.7))
                                .frame(width: 10, height: 10)
                            Text("Upload")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.cyan.opacity(0.7))
                                .frame(width: 10, height: 10)
                            Text("Download")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // Top apps using network
                // Top apps using network
                Text("Active Apps")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.topApps.isEmpty {
                    Text("Measuring...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.topApps) { app in
                        HStack(spacing: 6) {
                            Image(systemName: "app.fill")
                                .frame(width: 16)
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                            Text(app.name)
                                .font(.system(.caption, design: .default))
                                .lineLimit(1)
                            Spacer()
                            HStack(spacing: 8) {
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.orange)
                                    Text(formatSpeed(app.sendRate))
                                        .font(.system(size: 10, design: .monospaced))
                                }
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.cyan)
                                    Text(formatSpeed(app.recvRate))
                                        .font(.system(size: 10, design: .monospaced))
                                }
                            }
                        }
                    }
                }

                Divider()

                // Interface info
                InfoRow(label: "Interface", value: viewModel.activeInterface)
                InfoRow(label: "Local IP", value: viewModel.localIP)

                HStack(spacing: 8) {
                    Text("Public IP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.publicIP)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
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

                // Interfaces
                Text("Interfaces")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(viewModel.interfaces) { iface in
                    HStack {
                        Image(systemName: iconForType(iface.type))
                            .frame(width: 16)
                            .foregroundColor(colorForType(iface.type))
                        VStack(alignment: .leading) {
                            Text(iface.name)
                                .font(.system(.caption, design: .monospaced))
                            Text(iface.type.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(iface.ip)
                            .font(.system(.caption, design: .monospaced))
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(iface.ip, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                // Ping results
                Text("Ping Latency")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(viewModel.pingResults) { result in
                    HStack {
                        Circle()
                            .fill(result.isReachable ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(result.host)
                            .font(.system(.caption, design: .monospaced))
                        Spacer()
                        if let latency = result.latencyMs {
                            Text(String(format: "%.0f ms", latency))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(latencyColor(latency))
                        } else {
                            Text("...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // DNS Servers
                Text("DNS Servers")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.dnsServers.isEmpty {
                    Text("None detected")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.dnsServers, id: \.self) { server in
                        HStack {
                            Image(systemName: "server.rack")
                                .frame(width: 16)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(server)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(server, forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()

                // DNS Resolver
                Text("DNS Lookup")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("Domain name...", text: $viewModel.dnsQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                        .onSubmit {
                            viewModel.resolveDNS()
                        }

                    Button("Resolve") {
                        viewModel.resolveDNS()
                    }
                    .disabled(viewModel.dnsQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if viewModel.isDNSLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                ForEach(viewModel.dnsResults, id: \.self) { ip in
                    HStack {
                        Text(ip)
                            .font(.system(.caption, design: .monospaced))
                        Spacer()
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ip, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                // Session totals
                InfoRow(label: "Session Sent", value: formatBytes(viewModel.sessionBytesOut))
                InfoRow(label: "Session Received", value: formatBytes(viewModel.sessionBytesIn))

                Divider()

                // Actions
                HStack {
                    Button(action: { viewModel.refreshAll() }) {
                        Label("Refresh All", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                    }) {
                        Label("Activity Monitor", systemImage: "gauge.with.dots.needle.bottom.50percent")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
        .onAppear {
            viewModel.refreshAll()
        }
    }

    private func iconForType(_ type: InterfaceInfo.InterfaceType) -> String {
        switch type {
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .vpn: return "lock.shield"
        case .other: return "network"
        }
    }

    private func colorForType(_ type: InterfaceInfo.InterfaceType) -> Color {
        switch type {
        case .wifi: return .blue
        case .ethernet: return .green
        case .vpn: return .purple
        case .other: return .secondary
        }
    }

    private func latencyColor(_ ms: Double) -> Color {
        if ms < 50 { return .green }
        if ms < 150 { return .orange }
        return .red
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
