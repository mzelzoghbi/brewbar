import SwiftUI

struct IPMenuBarView: View {
    @ObservedObject var viewModel: IPConnectivityViewModel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.isOnline ? Color.green : Color.red)
                .frame(width: 6, height: 6)

            if viewModel.hasVPN {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.blue)
            }
        }
    }
}
