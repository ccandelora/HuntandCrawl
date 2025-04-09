import Foundation
import SwiftData

@Model
final class Team {
    var id: UUID
    var name: String
    var creatorId: UUID
    var huntId: UUID?
    var barCrawlId: UUID?
    var score: Int
    var memberIds: [UUID]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        creatorId: UUID,
        huntId: UUID? = nil,
        barCrawlId: UUID? = nil,
        score: Int = 0,
        memberIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.creatorId = creatorId
        self.huntId = huntId
        self.barCrawlId = barCrawlId
        self.score = score
        self.memberIds = memberIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 