import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var registry: ModuleRegistry

    var body: some View {
        HStack(spacing: 8) {
            ForEach(registry.enabledModules, id: \.id) { module in
                AnyView(module.menuBarView)
            }
        }
        .fixedSize()
    }
}
