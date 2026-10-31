import SwiftUI

struct ScanningView: View {
    let itemCount: Int

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(red: 0.165, green: 0.631, blue: 0.596))

            Text("Scanning…")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.933, green: 0.910, blue: 0.835))

            Text("\(itemCount.formatted()) items found")
                .font(.subheadline)
                .foregroundColor(Color(red: 0.165, green: 0.631, blue: 0.596))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.0, green: 0.169, blue: 0.212))
    }
}
