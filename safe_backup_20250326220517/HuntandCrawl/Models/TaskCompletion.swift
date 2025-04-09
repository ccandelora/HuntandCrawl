import Foundation
import SwiftData

@Model
class TaskCompletion {
    var id: UUID
    var taskId: UUID
    var huntId: UUID
    var userId: UUID?
    var completedAt: Date
    var points: Int
    var verificationMethod: String  // "location", "photo", "manual", etc.
    var evidenceData: Data?
    var isVerified: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        huntId: UUID,
        userId: UUID? = nil,
        completedAt: Date = Date(),
        points: Int = 0,
        verificationMethod: String,
        evidenceData: Data? = nil,
        isVerified: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.huntId = huntId
        self.userId = userId
        self.completedAt = completedAt
        self.points = points
        self.verificationMethod = verificationMethod
        self.evidenceData = evidenceData
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 