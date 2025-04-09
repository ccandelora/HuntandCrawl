import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var username: String
    var displayName: String
    var email: String?
    var profileImage: Data?
    var createdAt: Date
    var participatedHunts: [Hunt]?
    var createdHunts: [Hunt]?
    var totalPoints: Int
    var stateroom: String?
    var cruiseShip: String?
    
    init(username: String, displayName: String) {
        self.id = UUID()
        self.username = username
        self.displayName = displayName
        self.createdAt = Date()
        self.totalPoints = 0
    }
} 