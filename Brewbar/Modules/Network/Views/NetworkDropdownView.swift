import Charts
import SwiftUI

// MARK: - Reusable section card

private struct SectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(10)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(8)
    }
}

private struct SectionLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Main view

struct NetworkDropdownView: View {
    @ObservedObject var viewModel: NetworkViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Status bar
                SectionCard {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(viewModel.isOnline ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                                .shadow(color: viewModel.isOnline ? .green.opacity(0.5) : .red.opacity(0.5), radius: 4)
                            Text(viewModel.isOnline ? "Online" : "Offline")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Spacer()
                        if viewModel.hasVPN {
                            HStack(spacing: 3) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 10))
                                Text("VPN")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                        }
                    }
                }

                // Live speeds
                HStack(spacing: 8) {
                    SpeedCard(label: "Upload", value: formatSpeed(viewModel.uploadSpeed), icon: "arrow.up", color: .orange)
                    SpeedCard(label: "Download", value: formatSpeed(viewModel.downloadSpeed), icon: "arrow.down", color: .cyan)
                }

                // Traffic chart
                SectionCard {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(title: "Traffic History", icon: "chart.bar.fill")

                        Chart {
                            ForEach(Array(viewModel.downloadHistory.enumerated()), id: \.offset) { index, value in
                                BarMark(
                                    x: .value("Time", index),
                                    y: .value("Speed", value * 8 / 1_000_000)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.cyan.opacity(0.8), Color.cyan.opacity(0.4)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .cornerRadius(1)
                            }
                            ForEach(Array(viewModel.uploadHistory.enumerated()), id: \.offset) { index, value in
                                BarMark(
                                    x: .value("Time", index),
                                    y: .value("Speed", value * 8 / 1_000_000)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.8), Color.orange.opacity(0.4)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .cornerRadius(1)
                            }
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text("\(Int(v))")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                }
                            }
                        }
                        .frame(height: 70)

                        HStack(spacing: 12) {
                            LegendDot(color: .orange, label: "Upload")
                            LegendDot(color: .cyan, label: "Download")
                            Spacer()
                            Text("Mbps")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                }

                // Active apps
                if !viewModel.topApps.isEmpty {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(title: "Active Apps", icon: "app.badge.fill")

                            ForEach(viewModel.topApps) { app in
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.accentColor.opacity(0.6))
                                        .frame(width: 14, height: 14)
                                        .overlay(
                                            Image(systemName: "app.fill")
                                                .font(.system(size: 8))
                                                .foregroundColor(.white)
                                        )
                                    Text(app.name)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                    Spacer()
                                    HStack(spacing: 8) {
                                        SpeedBadge(icon: "arrow.up", value: formatSpeed(app.sendRate), color: .orange)
                                        SpeedBadge(icon: "arrow.down", value: formatSpeed(app.recvRate), color: .cyan)
                                    }
                                }
                            }
                        }
                    }
                }

                // Network info
                SectionCard {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(title: "Network Info", icon: "info.circle.fill")
                        InfoRow(label: "Interface", value: viewModel.activeInterface)
                        InfoRow(label: "Local IP", value: viewModel.localIP)
                        CopyableInfoRow(label: "Public IP", value: viewModel.publicIP)
                    }
                }

                // Interfaces
                if !viewModel.interfaces.isEmpty {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(title: "Interfaces", icon: "rectangle.connected.to.line.below")

                            ForEach(viewModel.interfaces) { iface in
                                HStack {
                                    Image(systemName: iconForType(iface.type))
                                        .frame(width: 14)
                                        .font(.system(size: 10))
                                        .foregroundColor(colorForType(iface.type))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(iface.name)
                                            .font(.system(size: 11, design: .monospaced))
                                        Text(iface.type.rawValue)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(iface.ip)
                                        .font(.system(size: 11, design: .monospaced))
                                    CopyButton(text: iface.ip)
                                }
                            }
                        }
                    }
                }

                // Ping + DNS Servers side by side
                HStack(alignment: .top, spacing: 8) {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(title: "Ping", icon: "bolt.horizontal.fill")

                            ForEach(viewModel.pingResults) { result in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(result.isReachable ? Color.green : Color.red)
                                        .frame(width: 5, height: 5)
                                    Text(result.host)
                                        .font(.system(size: 10, design: .monospaced))
                                    Spacer()
                                    if let latency = result.latencyMs {
                                        Text(String(format: "%.0fms", latency))
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundColor(latencyColor(latency))
                                    } else {
                                        Text("...")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    SectionCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(title: "DNS", icon: "server.rack")

                            if viewModel.dnsServers.isEmpty {
                                Text("--")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.dnsServers, id: \.self) { server in
                                    HStack(spacing: 4) {
                                        Text(server)
                                            .font(.system(size: 10, design: .monospaced))
                                        Spacer()
                                        CopyButton(text: server)
                                    }
                                }
                            }
                        }
                    }
                }

                // DNS Lookup
                SectionCard {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(title: "DNS Lookup", icon: "magnifyingglass")

                        HStack(spacing: 6) {
                            TextField("Domain name...", text: $viewModel.dnsQuery)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                                .onSubmit { viewModel.resolveDNS() }

                            Button(action: { viewModel.resolveDNS() }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.dnsQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        if viewModel.isDNSLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                        }

                        ForEach(viewModel.dnsResults, id: \.self) { ip in
                            HStack(spacing: 4) {
                                Text(ip)
                                    .font(.system(size: 10, design: .monospaced))
                                Spacer()
                                CopyButton(text: ip)
                            }
                        }
                    }
                }

                // Session totals
                SectionCard {
                    HStack(spacing: 0) {
                        SessionStat(label: "Sent", value: formatBytes(viewModel.sessionBytesOut), icon: "arrow.up.circle.fill", color: .orange)
                        Spacer()
                        Divider().frame(height: 24).opacity(0.3)
                        Spacer()
                        SessionStat(label: "Received", value: formatBytes(viewModel.sessionBytesIn), icon: "arrow.down.circle.fill", color: .cyan)
                    }
                }

                // Actions
                HStack(spacing: 12) {
                    Button(action: { viewModel.refreshAll() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9, weight: .semibold))
                            Text("Refresh")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                .font(.system(size: 9))
                            Text("Activity Monitor")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
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

// MARK: - Components

struct SpeedCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

struct SpeedBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.7))
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

struct SessionStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color.opacity(0.7))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
        }
    }
}

struct CopyableInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
            CopyButton(text: value)
        }
    }
}

struct CopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                copied = false
            }
        }) {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 9))
                .foregroundColor(copied ? .green : .secondary.opacity(0.6))
        }
        .buttonStyle(.plain)
    }
}
