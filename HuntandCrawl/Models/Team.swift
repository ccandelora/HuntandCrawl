import Foundation
import SwiftData

// Custom schema version struct to replace the missing SchemaVersion
struct CustomSchemaVersion: Hashable {
    let major: Int
    let minor: Int
    let patch: Int
    
    init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

// Define a schema and migration for Team
extension Schema {
    static var teamMigration: Schema {
        Schema([Team.self])
    }
}

@Model
final class Team {
    var id: String
    var name: String
    var creatorId: String
    var huntId: String?
    var barCrawlId: String?
    var score: Int
    
    // Store as a string instead of an array
    var _memberIdsString: String = ""
    
    @Transient
    var memberIds: [String] {
        get {
            return _memberIdsString.isEmpty ? [] : _memberIdsString.components(separatedBy: ",")
        }
        set {
            _memberIdsString = newValue.joined(separator: ",")
        }
    }
    
    var createdAt: Date
    var updatedAt: Date
    
    // Missing properties
    var teamDescription: String?
    var teamImageData: Data?
    var isPrivate: Bool?
    var captainId: String?
    
    // Fix circular reference with User
    @Relationship(deleteRule: .cascade, inverse: \User.teams)
    var members: [User]?
    
    // Fix circular references by removing the inverse
    @Relationship(deleteRule: .nullify, inverse: \Hunt.teams)
    var hunt: Hunt?
    
    @Relationship(deleteRule: .nullify, inverse: \BarCrawl.teams)
    var barCrawl: BarCrawl?
    
    // Add relationship for activeHunt
    @Relationship(deleteRule: .nullify)
    var activeHunt: Hunt?
    
    // Add relationship for completedHunts
    @Relationship(deleteRule: .nullify)
    var completedHunts: [Hunt]?
    
    // Computed properties
    var creator: User? {
        return members?.first { $0.id == creatorId }
    }
    
    var totalPoints: Int {
        return score
    }
    
    init(id: String = UUID().uuidString, name: String, creatorId: String = "", huntId: String? = nil, barCrawlId: String? = nil, score: Int = 0, memberIds: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date(), teamDescription: String? = nil, isPrivate: Bool? = false, teamImageData: Data? = nil, captainId: String? = nil) {
        self.id = id
        self.name = name
        self.creatorId = creatorId
        self.huntId = huntId
        self.barCrawlId = barCrawlId
        self.score = score
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPrivate = isPrivate
        self.teamDescription = teamDescription
        self.teamImageData = teamImageData
        self.captainId = captainId
        
        // Initialize the backing property directly after all stored properties are initialized
        self._memberIdsString = memberIds.joined(separator: ",")
    }
    
    convenience init(name: String) {
        self.init(name: name, creatorId: "", huntId: nil, barCrawlId: nil)
    }
} 