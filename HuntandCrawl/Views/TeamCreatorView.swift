import SwiftUI
import SwiftData

struct TeamCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var teamName = ""
    
    var body: some View {
        VStack {
            Text("Create Team")
                .font(.title)
                .padding()
            
            TextField("Team Name", text: $teamName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Create") {
                createTeam()
            }
            .disabled(teamName.isEmpty)
            .padding()
            
            Button("Cancel") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
    
    private func createTeam() {
        let team = Team(name: teamName)
        modelContext.insert(team)
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    TeamCreatorView()
        .modelContainer(for: Team.self, inMemory: true)
} 