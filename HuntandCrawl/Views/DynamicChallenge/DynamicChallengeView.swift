import SwiftUI
import SwiftData
import CoreLocation

struct DynamicChallengeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Dynamic Team Challenges")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This feature allows teams to generate and complete time-limited challenges.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Image(systemName: "bolt.fill")
                .font(.system(size: 72))
                .foregroundColor(.blue)
                .padding()
            
            Text("Feature Coming Soon")
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Team Challenges")
    }
}

#Preview {
    DynamicChallengeView()
        .environmentObject(NavigationManager())
} 