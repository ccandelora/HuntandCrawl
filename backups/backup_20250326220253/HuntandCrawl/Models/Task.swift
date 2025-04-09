import Foundation
import SwiftData

enum TaskType: String, Codable {
    case photo
    case location
    case item
    case question
    case activity
}

@Model
final class Task {
    var id: UUID
    var title: String
    var descriptionText: String
    var points: Int
    var type: TaskType
    var isCompleted: Bool
    var imageRequired: Bool
    var hint: String?
    var locationHint: String?
    var order: Int
    var latitude: Double
    var longitude: Double
    var requiredPhoto: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String,
        points: Int = 10,
        type: TaskType,
        isCompleted: Bool = false,
        imageRequired: Bool = false,
        hint: String? = nil,
        locationHint: String? = nil,
        order: Int = 0,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        requiredPhoto: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.points = points
        self.type = type
        self.isCompleted = isCompleted
        self.imageRequired = imageRequired
        self.hint = hint
        self.locationHint = locationHint
        self.order = order
        self.latitude = latitude
        self.longitude = longitude
        self.requiredPhoto = requiredPhoto
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 