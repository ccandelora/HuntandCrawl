import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingUserSettings = false
    @State private var showingCreateTeam = false
    
    // Example: Fetch the current user
    // You might pass the user in or fetch differently
    @Query(sort: \User.name) private var users: [User]
    private var currentUser: User? { users.first } // Adjust logic as needed
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let user = currentUser {
                        Text("Name: \(user.name)")
                        Text("Email: \(user.email)")
                        if let bio = user.bio {
                            Text("Bio: \(bio)")
                        }
                        // Add more user details if available
                    } else {
                        Text("Loading user...")
                    }
                    Button("User Settings") {
                        showingUserSettings = true
                    }
                }
                
                Section("My Content") {
                    // Links to user's created Hunts/Bar Crawls (Implement these views)
                    NavigationLink("My Hunts") {
                        // UserHuntsView()
                        Text("User Hunts (Not Implemented)")
                    }
                    NavigationLink("My Bar Crawls") {
                        // UserBarCrawlsView()
                        Text("User Bar Crawls (Not Implemented)")
                    }
                }
                
                Section("Teams") {
                     // Link to team management or creation
                    NavigationLink("My Teams") {
                         // UserTeamsView()
                         Text("Teams Management (Not Implemented)")
                    }
                     Button("Create New Team") {
                         showingCreateTeam = true
                     }
                 }
                
                // Add other sections like achievements, history, etc.
                
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingUserSettings) {
                // Replace with your actual settings view
                Text("User Settings View (Not Implemented)")
            }
             .sheet(isPresented: $showingCreateTeam) {
                 // Replace with your actual team creation view
                 Text("Create Team View (Not Implemented)")
             }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Define setup code outside the final View expression
        let previewContainer: ModelContainer = {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: User.self, configurations: config)
            let context = container.mainContext
            let sampleUser = User(name: "Preview User", email: "preview@example.com")
            context.insert(sampleUser)
            return container // Return the container
        }() // Immediately execute the closure
        
        // Return the View
        return NavigationStack {
            ProfileView()
                .modelContainer(previewContainer) // Use the prepared container
        }
    }
} 