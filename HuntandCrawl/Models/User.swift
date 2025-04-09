import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var name: String
    var email: String
    var avatarUrl: String?
    var bio: String?
    var createdAt: Date
    var updatedAt: Date?
    var displayName: String
    
    // Fix circular reference by removing the inverse
    @Relationship(deleteRule: .nullify)
    var teams: [Team]?
    
    // Add profile image property for UI
    var profileImage: Data?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        avatarUrl: String? = nil,
        bio: String? = nil,
        displayName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.createdAt = Date()
        self.displayName = displayName ?? name
    }
    
    // Convenience initializer for preview contexts
    init(username: String, displayName: String) {
        self.id = UUID().uuidString
        self.name = displayName
        self.email = username + "@example.com"
        self.createdAt = Date()
        self.displayName = displayName
    }
} 