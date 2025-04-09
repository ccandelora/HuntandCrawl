import SwiftUI
import SwiftData

struct TeamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let team: Team
    @State private var showingConfirmationDialog = false
    @State private var showingInviteSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Team Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(team.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if let activeHunt = team.activeHunt {
                            NavigationLink {
                                // Navigate to hunt detail
                            } label: {
                                Label("Active Hunt", systemImage: "flag.fill")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    
                    if let creator = team.creator {
                        HStack {
                            Text("Created by")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            NavigationLink {
                                // Navigate to user profile
                            } label: {
                                Text(creator.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Description Section
                if let description = team.teamDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        
                        Text(description)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Team Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Team Stats")
                        .font(.headline)
                    
                    HStack(spacing: 32) {
                        StatCard(
                            label: "Members",
                            value: team.members?.count ?? 0,
                            icon: "person.3.fill"
                        )
                        
                        StatCard(
                            label: "Total Hunts",
                            value: team.completedHunts?.count ?? 0,
                            icon: "flag.fill"
                        )
                        
                        StatCard(
                            label: "Points",
                            value: team.totalPoints,
                            icon: "star.fill"
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Active Hunt Section
                if let activeHunt = team.activeHunt {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Hunt")
                            .font(.headline)
                        
                        NavigationLink {
                            // Navigate to hunt detail
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(activeHunt.title)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text(activeHunt.huntDescription ?? "No description")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .foregroundColor(.secondary)
                                
                                ProgressView(value: Float(calculateProgress(for: activeHunt)))
                                    .tint(.green)
                                
                                HStack {
                                    Text("\(completedTasksCount(for: activeHunt)) of \(activeHunt.tasks?.count ?? 0) tasks completed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(calculateTeamPoints(for: activeHunt)) pts")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Team Members Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Team Members")
                        .font(.headline)
                    
                    if let members = team.members, !members.isEmpty {
                        ForEach(members) { member in
                            NavigationLink {
                                // Navigate to user profile
                            } label: {
                                HStack(spacing: 12) {
                                    if let profileImage = member.profileImage, let uiImage = UIImage(data: profileImage) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text(member.id == team.creator?.id ? "Creator" : "Member")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if member.id == team.creator?.id {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        Text("No members yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        showingInviteSheet = true
                    } label: {
                        Label("Invite Members", systemImage: "person.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    // Only show if user is the creator
                    if isUserCreator {
                        Button {
                            showingConfirmationDialog = true
                        } label: {
                            Label("Delete Team", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Team Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInviteSheet) {
            // TeamInviteView would go here
            Text("Invite Members Form")
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Are you sure you want to delete this team?",
            isPresented: $showingConfirmationDialog,
            titleVisibility: .visible
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
    
    private var isUserCreator: Bool {
        // In a real app, this would check if the current user is the creator
        true
    }
    
    private func deleteTeam() {
        modelContext.delete(team)
    }
    
    private func calculateProgress(for hunt: Hunt) -> Double {
        guard let tasks = hunt.tasks, !tasks.isEmpty else { return 0.0 }
        let completedCount = completedTasksCount(for: hunt)
        return Double(completedCount) / Double(tasks.count)
    }
    
    private func completedTasksCount(for hunt: Hunt) -> Int {
        guard let tasks = hunt.tasks else { return 0 }
        return tasks.filter { task in
            guard let completions = task.completions else { return false }
            return completions.contains { completion in
                guard let teamMembers = team.members else { return false }
                return teamMembers.contains { $0.id == completion.userId }
            }
        }.count
    }
    
    private func calculateTeamPoints(for hunt: Hunt) -> Int {
        guard let tasks = hunt.tasks else { return 0 }
        return tasks.reduce(0) { totalPoints, task in
            guard let completions = task.completions else { return totalPoints }
            let teamMemberCompletions = completions.filter { completion in
                guard let teamMembers = team.members else { return false }
                return teamMembers.contains { $0.id == completion.userId }
            }
            return totalPoints + (teamMemberCompletions.isEmpty ? 0 : task.points)
        }
    }
}

struct StatCard: View {
    let label: String
    let value: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(team: Team.example)
    }
    .modelContainer(PreviewContainer.previewContainer)
}

extension Team {
    static var example: Team {
        let team = Team(name: "Treasure Hunters")
        team.teamDescription = "We're a group of adventurous explorers who love to discover hidden gems and complete challenges together!"
        
        // Would typically create members and relationships here
        return team
    }
} 