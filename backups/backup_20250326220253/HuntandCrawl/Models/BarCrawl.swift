import Foundation
import SwiftData

@Model
final class BarCrawl {
    var id: UUID
    var title: String
    var descriptionText: String
    var createdAt: Date
    var startTime: Date?
    var endTime: Date?
    var isActive: Bool
    var isPublic: Bool
    var cruiseShip: String
    var coverImage: Data?
    var stops: [BarStop]?
    var theme: String?
    var createdBy: UUID
    var maxParticipants: Int?
    
    init(title: String, descriptionText: String, cruiseShip: String, createdBy: UUID, isPublic: Bool = false) {
        self.id = UUID()
        self.title = title
        self.descriptionText = descriptionText
        self.createdAt = Date()
        self.isActive = false
        self.isPublic = isPublic
        self.cruiseShip = cruiseShip
        self.createdBy = createdBy
        self.stops = []
    }
} 