import SwiftUI

struct OfflineView: View {
    var body: some View {
        VStack {
            Image(systemName: "wifi.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            Text("You are currently offline")
                .font(.headline)
                .padding(.bottom, 5)
            
            Text("Please connect to the internet to continue using all app features.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Offline")
    }
}

#Preview {
    OfflineView()
} 