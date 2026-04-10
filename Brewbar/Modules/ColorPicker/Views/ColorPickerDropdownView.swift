import SwiftUI

struct ColorPickerDropdownView: View {
    @ObservedObject var viewModel: ColorPickerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Pick button
                Button(action: { viewModel.pickColor() }) {
                    HStack {
                        Image(systemName: "eyedropper.halffull")
                        Text(viewModel.isPicking ? "Click anywhere..." : "Pick Color from Screen")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isPicking)

                // Current color
                if let picked = viewModel.currentColor {
                    ColorDetailView(picked: picked)
                } else {
                    Text("No color picked yet. Click above to sample a color from anywhere on screen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }

                // History
                if !viewModel.history.isEmpty {
                    Divider()

                    Text("Recent Colors")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        ForEach(viewModel.history) { color in
                            Button(action: {
                                viewModel.currentColor = color
                            }) {
                                VStack(spacing: 3) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color.swiftUIColor)
                                        .frame(width: 44, height: 32)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .strokeBorder(
                                                    viewModel.currentColor?.id == color.id
                                                        ? Color.accentColor
                                                        : Color.primary.opacity(0.2),
                                                    lineWidth: viewModel.currentColor?.id == color.id ? 2 : 0.5
                                                )
                                        )
                                    Text(color.hex)
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
            }
            .padding(12)
        }
    }
}

struct ColorDetailView: View {
    let picked: PickedColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Color preview
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(picked.swiftUIColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(picked.hex)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                    Text(picked.rgb)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }

            Divider()

            // All formats
            ColorValueRow(label: "HEX", value: picked.hex)
            ColorValueRow(label: "RGB", value: picked.rgb)
            ColorValueRow(label: "RGBA", value: picked.rgba)
            ColorValueRow(label: "HSL", value: picked.hsl)
            ColorValueRow(label: "SwiftUI", value: picked.swiftUI)
            ColorValueRow(label: "UIKit", value: picked.uiKit)
        }
    }
}

struct ColorValueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)
            Spacer()
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
    }
}
