import SwiftUI
import SwiftData

struct FriendsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var users: [User]
    
    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users.filter { $0.isFriend ?? false }
        } else {
            return users.filter { 
                ($0.isFriend ?? false) && 
                ($0.displayName.localizedCaseInsensitiveContains(searchText) || 
                 $0.username.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    var body: some View {
        List {
            if filteredUsers.isEmpty {
                ContentUnavailableView {
                    Label("No Friends Yet", systemImage: "person.2.slash")
                } description: {
                    Text("Start by adding friends to your network.")
                } actions: {
                    Button("Add Friend") {
                        showingAddFriendSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(filteredUsers) { user in
                    NavigationLink(destination: UserProfileView(user: user)) {
                        HStack(spacing: 12) {
                            // Profile image
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 44, height: 44)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.headline)
                                
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Online indicator
                            if Bool.random() { // Simulated online status
                                Circle()
                                    .fill(.green)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            removeFriend(user)
                        } label: {
                            Label("Remove", systemImage: "person.badge.minus")
                        }
                        
                        Button {
                            // Message friend
                        } label: {
                            Label("Message", systemImage: "message.fill")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search friends")
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddFriendSheet = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddFriendSheet) {
            AddFriendView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func removeFriend(_ user: User) {
        // Update friend status
        user.isFriend = false
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error removing friend: \(error)")
        }
    }
}

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @Query private var users: [User]
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users.filter { !($0.isFriend ?? false) }
        } else {
            return users.filter {
                (!($0.isFriend ?? false)) &&
                ($0.displayName.localizedCaseInsensitiveContains(searchText) ||
                 $0.username.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search by name or username", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                List {
                    if filteredUsers.isEmpty {
                        ContentUnavailableView("No Users Found", systemImage: "person.slash")
                    } else {
                        ForEach(filteredUsers) { user in
                            HStack {
                                // Profile image
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayName)
                                        .font(.headline)
                                    
                                    Text("@\(user.username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    addFriend(user)
                                } label: {
                                    Text("Add")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addFriend(_ user: User) {
        // Update friend status
        user.isFriend = true
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error adding friend: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
            .modelContainer(PreviewContainer.previewContainer)
            .environmentObject(NavigationManager())
    }
} 