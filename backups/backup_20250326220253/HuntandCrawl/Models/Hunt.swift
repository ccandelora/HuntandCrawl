import Foundation
import SwiftData

@Model
final class Hunt {
    var id: UUID
    var title: String
    var descriptionText: String
    var createdAt: Date
    var startTime: Date?
    var endTime: Date?
    var isActive: Bool
    var isPublic: Bool
    var location: String
    var coverImage: Data?
    var tasks: [Task]?
    var theme: String?
    var createdBy: UUID
    var maxParticipants: Int?
    
    init(title: String, descriptionText: String, location: String, createdBy: UUID, isPublic: Bool = false) {
        self.id = UUID()
        self.title = title
        self.descriptionText = descriptionText
        self.createdAt = Date()
        self.isActive = false
        self.isPublic = isPublic
        self.location = location
        self.createdBy = createdBy
        self.tasks = []
    }
} 