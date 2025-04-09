import Foundation
import SwiftData

@Model
final class Hunt {
    var id: String
    var name: String
    var huntDescription: String?
    var startTime: Date?
    var endTime: Date?
    var difficulty: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date?
    var creatorId: String?
    
    @Relationship(deleteRule: .cascade, inverse: \Task.hunt)
    var tasks: [Task]?
    
    @Relationship(deleteRule: .noAction)
    var creator: User?
    
    @Relationship(deleteRule: .nullify)
    var teams: [Team]?
    
    @Relationship(deleteRule: .nullify)
    var completedByTeams: [Team]?
    
    var title: String {
        return name
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        huntDescription: String? = nil,
        difficulty: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        isActive: Bool = true,
        creatorId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.huntDescription = huntDescription
        self.difficulty = difficulty
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = isActive
        self.createdAt = Date()
        self.creatorId = creatorId
    }
}

extension Hunt {
    var isCompleted: Bool {
        guard let tasks = tasks, !tasks.isEmpty else {
            return false
        }
        return tasks.allSatisfy { $0.isCompleted }
    }
    
    var isUpcoming: Bool {
        guard let startTime = startTime else {
            return false
        }
        return startTime > Date()
    }
    
    var isInProgress: Bool {
        guard let startTime = startTime, let endTime = endTime else {
            return isActive
        }
        let now = Date()
        return startTime <= now && now <= endTime && isActive
    }
} 