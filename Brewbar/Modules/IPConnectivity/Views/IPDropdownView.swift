import SwiftUI

struct IPDropdownView: View {
    @ObservedObject var viewModel: IPConnectivityViewModel

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

                // Public IP
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

                // DNS Resolver
                Text("DNS Resolver")
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

                Button(action: { viewModel.refreshAll() }) {
                    Label("Refresh All", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
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
