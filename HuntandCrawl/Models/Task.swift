import Foundation
import SwiftData
import CoreLocation
import MapKit

// Enum for verification methods
enum VerificationMethod: String, Codable {
    case photo = "PHOTO"
    case location = "LOCATION"
    case question = "QUESTION"
    case manual = "MANUAL"
}

@Model
final class Task {
    var id: String
    var title: String
    var subtitle: String?
    var taskDescription: String?
    var points: Int
    var verificationMethod: String
    var latitude: Double?
    var longitude: Double?
    var radius: Double?
    var question: String?
    var answer: String?
    var order: Int
    var createdAt: Date
    var updatedAt: Date?
    
    @Relationship(deleteRule: .cascade)
    var completions: [TaskCompletion]?
    
    @Relationship(deleteRule: .noAction)
    var hunt: Hunt?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        taskDescription: String? = nil,
        points: Int = 10,
        verificationMethod: VerificationMethod = .manual,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radius: Double? = nil,
        question: String? = nil,
        answer: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.taskDescription = taskDescription
        self.points = points
        self.verificationMethod = verificationMethod.rawValue
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.question = question
        self.answer = answer
        self.order = order
        self.createdAt = Date()
    }
    
    var hasLocation: Bool {
        return latitude != nil && longitude != nil
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isCompleted: Bool {
        guard let completions = completions, !completions.isEmpty else {
            return false
        }
        return completions.contains { $0.isVerified }
    }
} 