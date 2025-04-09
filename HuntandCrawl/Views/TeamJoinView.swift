import SwiftUI
import SwiftData

struct TeamJoinView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var teams: [Team]
    
    @State private var searchText = ""
    @State private var showOnlyPublicTeams = true
    @State private var showJoinCode = false
    @State private var joinCode = ""
    
    var filteredTeams: [Team] {
        if searchText.isEmpty {
            return showOnlyPublicTeams ? teams.filter { !($0.isPrivate ?? false) } : teams
        } else {
            let filtered = teams.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.teamDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            return showOnlyPublicTeams ? filtered.filter { !($0.isPrivate ?? false) } : filtered
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter controls
                VStack(spacing: 12) {
                    // Filter switch
                    Toggle("Show Only Public Teams", isOn: $showOnlyPublicTeams)
                        .padding(.horizontal)
                    
                    // Join by code button
                    Button {
                        showJoinCode = true
                    } label: {
                        Label("Join Team with Code", systemImage: "qrcode")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemGroupedBackground))
                
                // Team list
                List {
                    if filteredTeams.isEmpty {
                        ContentUnavailableView {
                            Label("No Teams Found", systemImage: "person.3.slash")
                        } description: {
                            Text("Try changing your search or filters.")
                        }
                    } else {
                        ForEach(filteredTeams) { team in
                            TeamRow(team: team) {
                                joinTeam(team)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search teams by name or description")
            .navigationTitle("Join Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Join with Team Code", isPresented: $showJoinCode) {
                TextField("Enter Team Code", text: $joinCode)
                
                Button("Cancel", role: .cancel) {
                    joinCode = ""
                }
                
                Button("Join") {
                    joinTeamWithCode(joinCode)
                    joinCode = ""
                }
                .disabled(joinCode.count < 6)
            } message: {
                Text("Enter the 6-digit code provided by the team captain.")
            }
        }
    }
    
    private func joinTeam(_ team: Team) {
        // In a real app, this would:
        // 1. Check if the team requires approval
        // 2. Either add the user directly or send a join request
        // 3. Update the UI accordingly
        
        // For this example, we'll just show feedback
        // TODO: Implement actual joining logic
        
        dismiss()
    }
    
    private func joinTeamWithCode(_ code: String) {
        // In a real app, this would:
        // 1. Validate the code against the database
        // 2. Add the user to the team if valid
        // 3. Show appropriate success/error messages
        
        // For this example, we'll just show feedback
        // TODO: Implement actual code joining logic
        
        // For demo purposes, let's assume the code is valid if it's 6 digits
        if code.count == 6 && code.allSatisfy({ $0.isNumber }) {
            // Success case would add user to team
            dismiss()
        } else {
            // Would show error in real app
            print("Invalid team code")
        }
    }
}

struct TeamRow: View {
    let team: Team
    let joinAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Team image
            if let imageData = team.teamImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Team info
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                
                if let description = team.teamDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text("\(team.members?.count ?? 0) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if team.isPrivate ?? false {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            // Join button
            Button {
                joinAction()
            } label: {
                Text("Join")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        TeamJoinView()
            .modelContainer(PreviewContainer.previewContainer)
            .environmentObject(NavigationManager())
    }
} 