import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // User preferences
    @AppStorage("allowNotifications") private var allowNotifications = true
    @AppStorage("locationPermission") private var locationPermission = true
    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("showNearbyAlerts") private var showNearbyAlerts = true
    @AppStorage("distanceUnit") private var distanceUnit = "miles"
    @AppStorage("dataSync") private var dataSync = true
    @AppStorage("autoCheckIn") private var autoCheckIn = false
    
    // Account details (would typically come from a user model)
    @State private var username = "current_user"
    @State private var email = "user@example.com"
    
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingEditProfileSheet = false
    
    var body: some View {
        List {
            // Account section
            Section("Account") {
                NavigationLink {
                    AccountDetailsView(username: username, email: email)
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(username)
                                .font(.headline)
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                }
                
                Button {
                    showingEditProfileSheet = true
                } label: {
                    Text("Edit Profile")
                }
                
                Button(role: .destructive) {
                    showingLogoutAlert = true
                } label: {
                    Text("Log Out")
                }
            }
            
            // Preferences section
            Section("Preferences") {
                Toggle("Allow Notifications", isOn: $allowNotifications)
                Toggle("Location Services", isOn: $locationPermission)
                Toggle("Dark Mode", isOn: $useDarkMode)
                Toggle("Nearby Alerts", isOn: $showNearbyAlerts)
                
                Picker("Distance Unit", selection: $distanceUnit) {
                    Text("Miles").tag("miles")
                    Text("Kilometers").tag("kilometers")
                }
            }
            
            // Data & Privacy section
            Section("Data & Privacy") {
                Toggle("Sync Data", isOn: $dataSync)
                Toggle("Auto Check-In", isOn: $autoCheckIn)
                
                NavigationLink("Data Usage") {
                    DataUsageView()
                }
                
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                
                Button(role: .destructive) {
                    showingDeleteAccountAlert = true
                } label: {
                    Text("Delete Account")
                }
            }
            
            // About section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink("Help & Support") {
                    HelpSupportView()
                }
                
                NavigationLink("Terms of Service") {
                    TermsOfServiceView()
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                // Handle logout
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Handle account deletion
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .sheet(isPresented: $showingEditProfileSheet) {
            NavigationStack {
                EditProfileView(username: $username, email: $email)
            }
        }
    }
}

struct AccountDetailsView: View {
    let username: String
    let email: String
    
    var body: some View {
        List {
            Section("Account Details") {
                DetailRow(title: "Username", value: username)
                DetailRow(title: "Email", value: email)
                DetailRow(title: "Member Since", value: "January 15, 2024")
                DetailRow(title: "Account Type", value: "Standard")
            }
            
            Section("Activity") {
                DetailRow(title: "Hunts Completed", value: "12")
                DetailRow(title: "Bar Crawls Joined", value: "5")
                DetailRow(title: "Total Points", value: "2,450")
                DetailRow(title: "Teams", value: "3")
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var username: String
    @Binding var email: String
    
    @State private var newUsername: String = ""
    @State private var newEmail: String = ""
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        Form {
            Section("Profile Information") {
                TextField("Username", text: $newUsername)
                TextField("Email", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section("Change Password") {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
            }
            
            Section {
                Button("Save Changes") {
                    // Update profile info
                    username = newUsername
                    email = newEmail
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(newUsername.isEmpty || newEmail.isEmpty)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            newUsername = username
            newEmail = email
        }
    }
}

struct DataUsageView: View {
    var body: some View {
        List {
            Section("Storage") {
                DataRow(title: "App Size", value: "45 MB")
                DataRow(title: "User Data", value: "12 MB")
                DataRow(title: "Cache", value: "8 MB")
            }
            
            Section("Network") {
                DataRow(title: "Cellular Data", value: "3.2 MB this month")
                DataRow(title: "Wi-Fi Data", value: "18.5 MB this month")
                DataRow(title: "Background Data", value: "1.8 MB this month")
            }
            
            Section {
                Button("Clear Cache") {
                    // Handle cache clearing
                }
                
                Button(role: .destructive) {
                    // Handle data reset
                } label: {
                    Text("Reset All App Data")
                }
            }
        }
        .navigationTitle("Data Usage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: March 1, 2024")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("This is a placeholder for the privacy policy content. In a real app, this would contain detailed information about how user data is collected, stored, used, and protected.")
                
                Text("Topics typically covered include:")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    BulletPoint("What information we collect")
                    BulletPoint("How we use your information")
                    BulletPoint("How we share your information")
                    BulletPoint("Data retention and deletion")
                    BulletPoint("Your rights and choices")
                    BulletPoint("Children's privacy")
                    BulletPoint("Changes to this policy")
                    BulletPoint("Contact information")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.headline)
            Text(text)
        }
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: March 1, 2024")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("This is a placeholder for the terms of service content. In a real app, this would contain detailed legal information about the rules, regulations, and guidelines for using the app.")
                
                Text("Sections typically included:")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    BulletPoint("Acceptance of Terms")
                    BulletPoint("User Accounts")
                    BulletPoint("Prohibited Activities")
                    BulletPoint("Content Guidelines")
                    BulletPoint("Intellectual Property Rights")
                    BulletPoint("Disclaimers and Warranties")
                    BulletPoint("Limitation of Liability")
                    BulletPoint("Dispute Resolution")
                    BulletPoint("Termination")
                    BulletPoint("Changes to Terms")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpSupportView: View {
    @State private var subject = ""
    @State private var message = ""
    @State private var showingThankYou = false
    
    var body: some View {
        Form {
            Section("FAQ") {
                DisclosureGroup("How do I create a scavenger hunt?") {
                    Text("Navigate to the Create tab and select 'New Scavenger Hunt'. Follow the step-by-step guide to add tasks, set locations, and invite participants.")
                        .padding(.vertical, 8)
                }
                
                DisclosureGroup("How do location verifications work?") {
                    Text("Tasks with location verification require participants to be physically present at the specified location to complete the task. The app uses your device's GPS to verify your presence.")
                        .padding(.vertical, 8)
                }
                
                DisclosureGroup("Can I use the app offline?") {
                    Text("Yes, most features work offline. Your completions will sync when you regain connection. However, some features like real-time team tracking require an active internet connection.")
                        .padding(.vertical, 8)
                }
            }
            
            Section("Contact Support") {
                TextField("Subject", text: $subject)
                
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("Describe your issue...")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }
                
                Button("Submit") {
                    showingThankYou = true
                    
                    // Reset form after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        subject = ""
                        message = ""
                        showingThankYou = false
                    }
                }
                .disabled(subject.isEmpty || message.isEmpty)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(showingThankYou ? 0 : 1)
                .overlay {
                    if showingThankYou {
                        Text("Thank you! We'll respond soon.")
                            .foregroundColor(.green)
                    }
                }
            }
            
            Section("Connect") {
                LinkRow(title: "Twitter", icon: "bird", url: "https://twitter.com")
                LinkRow(title: "Discord Community", icon: "bubble.left.and.bubble.right", url: "https://discord.com")
                LinkRow(title: "Email Support", icon: "envelope", url: "mailto:support@huntandcrawl.com")
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LinkRow: View {
    let title: String
    let icon: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(PreviewContainer.previewContainer)
            .environmentObject(NavigationManager())
    }
} 