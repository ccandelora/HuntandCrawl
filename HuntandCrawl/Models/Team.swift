import Foundation
import SwiftData

@Model
final class Team {
    var id: String
    var name: String
    var creatorId: String
    var huntId: String?
    var barCrawlId: String?
    var score: Int
    var memberIds: [String]
    var createdAt: Date
    var updatedAt: Date
    
    // Missing properties
    var teamDescription: String?
    var teamImageData: Data?
    var isPrivate: Bool?
    
    // Fix circular reference with User
    @Relationship(deleteRule: .cascade)
    var members: [User]?
    
    // Fix circular references by removing the inverse
    @Relationship(deleteRule: .nullify)
    var activeHunt: Hunt?
    
    @Relationship(deleteRule: .nullify)
    var completedHunts: [Hunt]?
    
    // Computed properties
    var creator: User? {
        return members?.first { $0.id == creatorId }
    }
    
    var totalPoints: Int {
        return score
    }
    
    init(id: String = UUID().uuidString, name: String, creatorId: String = "", huntId: String? = nil, barCrawlId: String? = nil, score: Int = 0, memberIds: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.creatorId = creatorId
        self.huntId = huntId
        self.barCrawlId = barCrawlId
        self.score = score
        self.memberIds = memberIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPrivate = false
    }
    
    convenience init(name: String) {
        self.init(name: name, creatorId: "", huntId: nil, barCrawlId: nil)
    }
} 