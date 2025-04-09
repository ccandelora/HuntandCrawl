import SwiftUI
import SwiftData

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [Notification] = []
    
    // Sample notification structure
    struct Notification: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let timestamp: Date
        let isRead: Bool
        let type: NotificationType
    }
    
    enum NotificationType {
        case invitation, completion, system, achievement
    }
    
    var body: some View {
        List {
            if notifications.isEmpty {
                ContentUnavailableView(
                    "No Notifications",
                    systemImage: "bell.slash",
                    description: Text("You don't have any notifications yet.")
                )
            } else {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !notifications.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark All Read") {
                        // Action to mark all notifications as read
                    }
                }
            }
        }
        .onAppear {
            loadSampleNotifications()
        }
    }
    
    private func loadSampleNotifications() {
        notifications = [
            Notification(
                title: "Team Invitation",
                message: "John Smith has invited you to join Team Adventure",
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                isRead: false,
                type: .invitation
            ),
            Notification(
                title: "Task Completed",
                message: "Your task 'Take a photo at the fountain' has been verified",
                timestamp: Date().addingTimeInterval(-10800), // 3 hours ago
                isRead: true,
                type: .completion
            ),
            Notification(
                title: "New Hunt Available",
                message: "Downtown Explorer hunt is now available to join",
                timestamp: Date().addingTimeInterval(-86400), // 1 day ago
                isRead: false,
                type: .system
            ),
            Notification(
                title: "Achievement Unlocked",
                message: "You've completed 5 tasks! You've earned the 'Explorer' badge.",
                timestamp: Date().addingTimeInterval(-172800), // 2 days ago
                isRead: true,
                type: .achievement
            )
        ]
    }
}

struct NotificationRow: View {
    let notification: NotificationsView.Notification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Circle()
                .fill(iconColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if !notification.isRead {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(notification.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }
    
    private var iconName: String {
        switch notification.type {
        case .invitation:
            return "person.2.fill"
        case .completion:
            return "checkmark.circle.fill"
        case .system:
            return "bell.fill"
        case .achievement:
            return "trophy.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .invitation:
            return .blue
        case .completion:
            return .green
        case .system:
            return .orange
        case .achievement:
            return .purple
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
} 