import SwiftUI

struct ColorPickerDropdownView: View {
    @ObservedObject var viewModel: ColorPickerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Pick button
                Button(action: { viewModel.pickColor() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "eyedropper.halffull")
                            .font(.system(size: 14, weight: .medium))
                        Text(viewModel.isPicking ? "Click anywhere..." : "Pick Color from Screen")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.08)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isPicking)

                // Current color
                if let picked = viewModel.currentColor {
                    ColorDetailView(picked: picked)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "eyedropper")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("Pick a color from anywhere on screen")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                // History
                if !viewModel.history.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("RECENT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 6) {
                        ForEach(viewModel.history) { color in
                            Button(action: {
                                viewModel.currentColor = color
                            }) {
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(color.swiftUIColor)
                                        .frame(height: 36)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(
                                                    viewModel.currentColor?.id == color.id
                                                        ? Color.accentColor
                                                        : Color.primary.opacity(0.15),
                                                    lineWidth: viewModel.currentColor?.id == color.id ? 2 : 0.5
                                                )
                                        )
                                        .shadow(color: color.swiftUIColor.opacity(0.3), radius: viewModel.currentColor?.id == color.id ? 4 : 0)
                                    Text(color.hex)
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
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
        VStack(alignment: .leading, spacing: 10) {
            // Color preview
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(picked.swiftUIColor)
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: picked.swiftUIColor.opacity(0.4), radius: 8, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(picked.hex)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .textSelection(.enabled)
                    Text(picked.rgb)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }

            // All formats in a card
            VStack(spacing: 0) {
                ColorValueRow(label: "HEX", value: picked.hex, isFirst: true)
                ColorValueRow(label: "RGB", value: picked.rgb)
                ColorValueRow(label: "RGBA", value: picked.rgba)
                ColorValueRow(label: "HSL", value: picked.hsl)
                ColorValueRow(label: "SwiftUI", value: picked.swiftUI)
                ColorValueRow(label: "UIKit", value: picked.uiKit, isLast: true)
            }
            .background(Color.primary.opacity(0.04))
            .cornerRadius(8)
        }
    }
}

struct ColorValueRow: View {
    let label: String
    let value: String
    var isFirst: Bool = false
    var isLast: Bool = false
    @State private var copied = false

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .trailing)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)
            Spacer()
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    copied = false
                }
            }) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 9))
                    .foregroundColor(copied ? .green : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider().opacity(0.3).padding(.leading, 66)
            }
        }
    }
}
