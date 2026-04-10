import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var registry: ModuleRegistry
    @ObservedObject var contextEngine: ContextEngine
    @State private var selectedModuleId: String?

    var body: some View {
        VStack(spacing: 0) {
            // Module tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(registry.enabledModules, id: \.id) { module in
                        Button(action: {
                            selectedModuleId = module.id
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: module.icon)
                                Text(module.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                selectedModuleId == module.id
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Divider()

            // Selected module content
            if let moduleId = selectedModuleId ?? registry.enabledModules.first?.id,
               let module = registry.enabledModules.first(where: { $0.id == moduleId })
            {
                AnyView(module.dropdownView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Spacer()
                Text("No modules enabled")
                    .foregroundColor(.secondary)
                Spacer()
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Settings...") {
                    AppDelegate.shared?.openSettings()
                }
                .buttonStyle(.plain)
                .font(.caption)

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 360, height: 480)
    }
}
