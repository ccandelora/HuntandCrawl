import SwiftUI
import SwiftData

struct TeamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let team: Team
    @State private var showingConfirmationDialog = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(team.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                
            if let description = team.teamDescription {
                Text(description)
                    .font(.body)
                    .padding()
            }
            
            Spacer()
            
            Button("Delete Team") {
                showingConfirmationDialog = true
            }
            .foregroundColor(.red)
            .padding()
        }
        .padding()
        .confirmationDialog(
            "Are you sure you want to delete this team?",
            isPresented: $showingConfirmationDialog
        ) {
            Button("Delete", role: .destructive) {
                deleteTeam()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func deleteTeam() {
        modelContext.delete(team)
    }
}

#Preview {
    TeamDetailView(team: Team(name: "Preview Team"))
        .modelContainer(for: Team.self, inMemory: true)
} 