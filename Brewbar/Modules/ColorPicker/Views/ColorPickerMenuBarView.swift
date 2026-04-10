import SwiftUI

struct ColorPickerMenuBarView: View {
    @ObservedObject var viewModel: ColorPickerViewModel

    var body: some View {
        Button(action: {
            viewModel.pickColor()
        }) {
            Image(systemName: "eyedropper")
                .font(.system(size: 12, weight: .medium))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
