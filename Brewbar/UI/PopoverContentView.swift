import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var registry: ModuleRegistry
    @ObservedObject var contextEngine: ContextEngine
    @State private var selectedModuleId: String?
    var initialModuleId: String?

    var body: some View {
        VStack(spacing: 0) {
            // Module tab bar
            HStack(spacing: 4) {
                ForEach(registry.enabledModules, id: \.id) { module in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedModuleId = module.id
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: module.icon)
                                .font(.system(size: 11, weight: .medium))
                            Text(module.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedModuleId == module.id
                                ? Color.accentColor.opacity(0.15)
                                : Color.primary.opacity(0.05)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(
                                    selectedModuleId == module.id
                                        ? Color.accentColor.opacity(0.3)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            // Selected module content
            let enabled = registry.enabledModules
            let activeId = enabled.contains(where: { $0.id == selectedModuleId }) ? selectedModuleId : enabled.first?.id
            if let moduleId = activeId,
               let module = enabled.first(where: { $0.id == moduleId })
            {
                AnyView(module.dropdownView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Spacer()
                Text("No modules enabled")
                    .foregroundColor(.secondary)
                Spacer()
            }

            Divider().opacity(0.5)

            // Footer
            HStack(spacing: 16) {
                Text("Brewbar")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
                Spacer()
                Button(action: { AppDelegate.shared?.openSettings() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "gear")
                            .font(.system(size: 10))
                        Text("Settings")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: { NSApp.terminate(nil) }) {
                    Text("Quit")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 370, height: 500)
        .onAppear {
            if let initialModuleId {
                selectedModuleId = initialModuleId
            }
        }
    }
}
