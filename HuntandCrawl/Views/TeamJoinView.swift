import SwiftUI
import SwiftData

struct TeamJoinView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var teams: [Team]
    
    @State private var searchText = ""
    @State private var showPublicTeamsOnly = false
    @State private var showingJoinByCodeAlert = false
    @State private var teamCode = ""
    
    // Get the current user (in a real app, this would come from authentication)
    private var currentUser: User? {
        // Placeholder implementation
        return nil
    }
    
    var filteredTeams: [Team] {
        teams.filter { team in
            let matchesSearch = searchText.isEmpty || 
                               team.name.localizedCaseInsensitiveContains(searchText) ||
                               (team.teamDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesVisibility = !showPublicTeamsOnly || !(team.isPrivate ?? false)
            
            // Don't show teams the user is already a member of
            let notMember = !(team.memberIds.contains(where: { $0 == currentUser?.id ?? "" }))
            
            return matchesSearch && matchesVisibility && notMember
        }
    }
    
    var body: some View {
        VStack {
            // Search and filter options
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search teams", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Toggle(isOn: $showPublicTeamsOnly) {
                    Label("Show public teams only", systemImage: "eye")
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Button {
                    showingJoinByCodeAlert = true
                } label: {
                    Label("Join team with code", systemImage: "ticket")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(15)
            .padding(.horizontal)
            
            // Teams list
            List {
                if filteredTeams.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.sequence")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No teams found")
                            .font(.headline)
                        
                        Text("Try adjusting your search or create a new team")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredTeams) { team in
                        TeamRow(team: team)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                requestToJoinTeam(team)
                            }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Join a Team")
        .alert("Join Team by Code", isPresented: $showingJoinByCodeAlert) {
            TextField("Enter team code", text: $teamCode)
            
            Button("Cancel", role: .cancel) {
                teamCode = ""
            }
            
            Button("Join") {
                joinTeamByCode(teamCode)
                teamCode = ""
            }
        } message: {
            Text("Enter the team code provided by the team admin.")
        }
    }
    
    private func requestToJoinTeam(_ team: Team) {
        // For public teams, join directly
        if !(team.isPrivate ?? false) {
            joinTeam(team)
        } else {
            // For private teams, send a join request
            sendJoinRequest(to: team)
        }
    }
    
    private func joinTeam(_ team: Team) {
        guard let currentUser = currentUser else { return }
        
        // Add user to team members
        var memberIds = team.memberIds
        memberIds.append(currentUser.id)
        team.memberIds = memberIds
        
        // Create a notification for team members
        createNotification(for: team, message: "\(currentUser.displayName) has joined the team.")
        
        dismiss()
    }
    
    private func sendJoinRequest(to team: Team) {
        // In a real app, create a TeamJoinRequest object
        // and notify the team admin
        
        // Show a confirmation to the user
        // (in a real app, use an alert or toast)
        print("Join request sent to \(team.name)")
    }
    
    private func joinTeamByCode(_ code: String) {
        // Find team with matching code
        if let team = teams.first(where: { $0.id == code }) {
            joinTeam(team)
        } else {
            // Show error (in a real app, use an alert)
            print("Invalid team code")
        }
    }
    
    private func createNotification(for team: Team, message: String) {
        // In a real app, create a Notification object
        // for team members to see
    }
}

struct TeamRow: View {
    let team: Team
    
    var body: some View {
        HStack(spacing: 16) {
            // Team image
            if let imageData = team.teamImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 30))
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                    .foregroundColor(.blue)
            }
            
            // Team info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(team.name)
                        .font(.headline)
                    
                    if team.isPrivate ?? false {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let description = team.teamDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    Label("\(team.memberIds.count) members", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let huntCount = team.completedHunts?.count, huntCount > 0 {
                        Label("\(huntCount) hunts", systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("\(team.score) pts", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Join button/icon
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        TeamJoinView()
    }
    .modelContainer(PreviewContainer.previewContainer)
} 