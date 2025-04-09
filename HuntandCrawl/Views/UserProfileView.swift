import SwiftUI
import SwiftData
import PhotosUI
import _Concurrency

// Alternative approach that doesn't rely on complex async patterns
class PhotoLoader {
    func loadPhoto(from item: PhotosPickerItem, completion: @escaping (Data?) -> Void) {
        // Use a callback-based approach to avoid Task name conflicts
        let processor = ProfilePhotoProcessor()
        processor.process(item: item, completion: completion)
    }
}

// Helper class to avoid Task name conflicts
fileprivate class ProfilePhotoProcessor {
    func process(item: PhotosPickerItem, completion: @escaping (Data?) -> Void) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                completion(data)
            case .failure:
                completion(nil)
            }
        }
    }
}

struct UserProfileView: View {
    @Environment(\.modelContext) private var modelContext
    
    let user: User
    @State private var isCurrentUser = false // Would be determined by auth service
    @State private var showingEditSheet = false
    @State private var showingPhotosPicker = false
    @State private var selectedItem: PhotosPickerItem?
    private let photoLoader = PhotoLoader()
    
    @Query(sort: \Hunt.createdAt, order: .reverse) var allHunts: [Hunt]
    @Query(sort: \Team.name) var allTeams: [Team]
    
    var userHunts: [Hunt] {
        allHunts.filter { $0.creatorId == user.id }
    }
    
    var userTeams: [Team] {
        allTeams.filter { team in
            guard let members = team.members else { return false }
            return members.contains { $0.id == user.id }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack {
                    // Profile Picture
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let profileImage = user.profileImage, let uiImage = UIImage(data: profileImage) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                        
                        if isCurrentUser {
                            Button {
                                showingPhotosPicker = true
                            } label: {
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.top)
                    
                    // User Name & Bio
                    Text(user.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // User Stats
                    HStack(spacing: 32) {
                        StatView(value: userHunts.count, label: "Created")
                        StatView(value: userTeams.count, label: "Teams")
                        StatView(value: userCompletedTasks, label: "Completed")
                        StatView(value: userTotalPoints, label: "Points")
                    }
                    .padding(.top, 12)
                    
                    // Edit Profile Button (if current user)
                    if isCurrentUser {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                                .font(.headline)
                                .frame(width: 200)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Created Hunts Section
                if !userHunts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Created Hunts")
                                .font(.headline)
                            
                            Spacer()
                            
                            if userHunts.count > 3 {
                                NavigationLink {
                                    UserHuntsListView(hunts: userHunts)
                                } label: {
                                    Text("See All")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        ForEach(Array(userHunts.prefix(3))) { hunt in
                            NavigationLink {
                                // Navigate to hunt detail
                            } label: {
                                HuntCardView(hunt: hunt)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Teams Section
                if !userTeams.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Teams")
                                .font(.headline)
                            
                            Spacer()
                            
                            if userTeams.count > 3 {
                                NavigationLink {
                                    UserTeamsListView(teams: userTeams)
                                } label: {
                                    Text("See All")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        ForEach(Array(userTeams.prefix(3))) { team in
                            NavigationLink {
                                TeamDetailView(team: team)
                            } label: {
                                TeamCardView(team: team)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Recent Activity Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                    
                    if let recentActivities = user.recentActivities, !recentActivities.isEmpty {
                        ForEach(recentActivities) { activity in
                            ActivityRow(activity: activity)
                        }
                    } else {
                        Text("No recent activity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedItem)
        .onChange(of: selectedItem) { _, newValue in
            if let newValue {
                loadTransferable(from: newValue)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            // UserProfileEditView would go here
            Text("Edit Profile Form")
                .presentationDetents([.medium, .large])
        }
    }
    
    private var userCompletedTasks: Int {
        // In a real app, would calculate from user's task completions
        return 28
    }
    
    private var userTotalPoints: Int {
        // In a real app, would calculate from user's completed tasks
        return 875
    }
    
    private func loadTransferable(from item: PhotosPickerItem) {
        photoLoader.loadPhoto(from: item) { data in
            if let data = data {
                // In a real app, would update the user's profile image
            }
        }
    }
}

struct StatView: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct HuntCardView: View {
    let hunt: Hunt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hunt.name)
                .font(.headline)
                .lineLimit(1)
            
            if let description = hunt.huntDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(hunt.tasks?.count ?? 0) tasks", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDate(hunt.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct TeamCardView: View {
    let team: Team
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Team Icon or Members Preview
            Group {
                if let members = team.members, !members.isEmpty {
                    ZStack(alignment: .center) {
                        ForEach(Array(members.prefix(3).enumerated()), id: \.offset) { index, member in
                            if let profileImage = member.profileImage, let uiImage = UIImage(data: profileImage) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                    .offset(x: CGFloat(index * 12))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                    .foregroundColor(.gray)
                                    .offset(x: CGFloat(index * 12))
                            }
                        }
                    }
                    .frame(width: 60, height: 40)
                } else {
                    Image(systemName: "person.3.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                
                if let description = team.teamDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Label("\(team.members?.count ?? 0) members", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let activeHunt = team.activeHunt {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(activeHunt.name, systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(10)
    }
}

struct ActivityRow: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Icon
            Image(systemName: activityIcon)
                .font(.system(size: 24))
                .foregroundColor(activityColor)
                .frame(width: 40, height: 40)
                .background(activityColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activityTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatDate(activity.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var activityIcon: String {
        switch activity.type {
        case .completedTask:
            return "checkmark.circle.fill"
        case .createdHunt:
            return "map.fill"
        case .joinedTeam:
            return "person.3.fill"
        case .visitedBar:
            return "wineglass.fill"
        }
    }
    
    private var activityColor: Color {
        switch activity.type {
        case .completedTask:
            return .green
        case .createdHunt:
            return .blue
        case .joinedTeam:
            return .purple
        case .visitedBar:
            return .orange
        }
    }
    
    private var activityTitle: String {
        switch activity.type {
        case .completedTask:
            return "Completed task: \(activity.title)"
        case .createdHunt:
            return "Created hunt: \(activity.title)"
        case .joinedTeam:
            return "Joined team: \(activity.title)"
        case .visitedBar:
            return "Visited: \(activity.title)"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct UserHuntsListView: View {
    let hunts: [Hunt]
    
    var body: some View {
        List(hunts) { hunt in
            NavigationLink {
                // HuntDetailView(hunt: hunt)
            } label: {
                HuntCardView(hunt: hunt)
            }
        }
        .navigationTitle("Created Hunts")
    }
}

struct UserTeamsListView: View {
    let teams: [Team]
    
    var body: some View {
        List(teams) { team in
            NavigationLink {
                TeamDetailView(team: team)
            } label: {
                TeamCardView(team: team)
            }
        }
        .navigationTitle("Teams")
    }
}

// For preview
struct UserActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let date: Date
    
    enum ActivityType {
        case completedTask
        case createdHunt
        case joinedTeam
        case visitedBar
    }
}

extension User {
    var recentActivities: [UserActivity]? {
        // In a real app, would be calculated from user's actions
        let calendar = Calendar.current
        return [
            UserActivity(
                type: .completedTask,
                title: "Find the Golden Gate",
                date: calendar.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            ),
            UserActivity(
                type: .visitedBar,
                title: "The Tipsy Tavern",
                date: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            UserActivity(
                type: .joinedTeam,
                title: "Adventure Seekers",
                date: calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            UserActivity(
                type: .createdHunt,
                title: "Downtown Explorer",
                date: calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            )
        ]
    }
}

#Preview {
    NavigationStack {
        UserProfileView(user: User.example)
    }
    .modelContainer(PreviewContainer.previewContainer)
}

extension User {
    static var example: User {
        let user = User(id: "user123", name: "Alex Johnson", email: "user@example.com", displayName: "Alex Johnson")
        user.bio = "Adventure enthusiast and craft beer lover. Always looking for the next exciting challenge!"
        return user
    }
} 