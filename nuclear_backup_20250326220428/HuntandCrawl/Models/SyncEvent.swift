import Foundation
import SwiftData

@Model
class SyncEvent {
    var id: UUID
    var eventType: String
    var entityId: UUID
    var data: Data?
    var createdAt: Date
    var syncAttempts: Int
    var lastSyncAttempt: Date?
    
    init(
        id: UUID = UUID(),
        eventType: String,
        entityId: UUID,
        data: Data? = nil,
        createdAt: Date = Date(),
        syncAttempts: Int = 0,
        lastSyncAttempt: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.entityId = entityId
        self.data = data
        self.createdAt = createdAt
        self.syncAttempts = syncAttempts
        self.lastSyncAttempt = lastSyncAttempt
    }
} 