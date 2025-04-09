import SwiftUI
import SwiftData
import PhotosUI

struct TeamCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var teamName = ""
    @State private var teamDescription = ""
    @State private var isPrivate = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var teamImageData: Data?
    @State private var showingUserPicker = false
    @State private var selectedUserIds: Set<UUID> = []
    
    @Query private var users: [User]
    
    var isValid: Bool {
        !teamName.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Team Information") {
                    TextField("Team Name", text: $teamName)
                    
                    TextField("Team Description (Optional)", text: $teamDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Toggle("Private Team", isOn: $isPrivate)
                }
                
                Section("Team Photo") {
                    HStack {
                        Spacer()
                        
                        if let imageData = teamImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary, lineWidth: 1)
                                )
                        } else {
                            Image(systemName: "person.3.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(.blue.opacity(0.7))
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        Label(teamImageData == nil ? "Select Team Photo" : "Change Team Photo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .onChange(of: selectedPhotoItem) {
                        Task {
                            if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                                teamImageData = data
                            }
                        }
                    }
                }
                
                Section("Team Members") {
                    Button {
                        showingUserPicker = true
                    } label: {
                        Label("Add Team Members", systemImage: "person.badge.plus")
                    }
                    
                    if !selectedUserIds.isEmpty {
                        ForEach(users.filter { selectedUserIds.contains($0.id) }) { user in
                            HStack {
                                Text(user.displayName)
                                Spacer()
                                Button {
                                    selectedUserIds.remove(user.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        createTeam()
                    } label: {
                        Text("Create Team")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Create Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUserPicker) {
                UserPickerView(selectedUserIds: $selectedUserIds)
            }
        }
    }
    
    private func createTeam() {
        // Get current user ID (for now, we'll use a mock ID)
        let currentUserId = UUID()
        
        // Create the new team
        let team = Team(
            name: teamName,
            teamDescription: teamDescription.isEmpty ? nil : teamDescription,
            isPrivate: isPrivate,
            captainId: currentUserId,
            teamImageData: teamImageData
        )
        
        // Add selected members to the team
        for userId in selectedUserIds {
            if let user = users.first(where: { $0.id == userId }) {
                team.addToMembers(user)
            }
        }
        
        // Add current user as a member and captain
        if let currentUser = users.first(where: { $0.id == currentUserId }) {
            team.addToMembers(currentUser)
        }
        
        // Save to model context
        modelContext.insert(team)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving team: \(error)")
            // In a real app, you'd show an error message to the user
        }
    }
}

struct UserPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedUserIds: Set<UUID>
    
    @Query private var users: [User]
    @State private var searchText = ""
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredUsers) { user in
                    HStack {
                        // User info
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Selection checkbox
                        Image(systemName: selectedUserIds.contains(user.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedUserIds.contains(user.id) ? .blue : .gray)
                            .font(.title2)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(for: user)
                    }
                }
            }
            .navigationTitle("Select Members")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search users")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleSelection(for user: User) {
        if selectedUserIds.contains(user.id) {
            selectedUserIds.remove(user.id)
        } else {
            selectedUserIds.insert(user.id)
        }
    }
}

#Preview {
    let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: User.self, Team.self, configurations: config)
        let context = container.mainContext
        
        // Create sample users
        let sampleUsers = [
            User(username: "alex_j", displayName: "Alex Johnson"),
            User(username: "emma1990", displayName: "Emma Williams"),
            User(username: "david_m", displayName: "David Martinez"),
            User(username: "sarah_c", displayName: "Sarah Chen"),
            User(username: "mike_s", displayName: "Mike Smith")
        ]
        
        for user in sampleUsers {
            context.insert(user)
        }
        
        return container
    }()
    
    return TeamCreatorView()
        .modelContainer(previewContainer)
} 