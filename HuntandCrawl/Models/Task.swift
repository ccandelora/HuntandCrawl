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
final class HuntTask {
    var id: String
    var title: String
    var subtitle: String?
    var taskDescription: String?
    var points: Int
    var verificationMethod: String
    // Replace GPS coordinates with ship-specific location
    var deckNumber: Int?
    var locationOnShip: String?
    var section: String? // Forward, Midship, Aft
    var proximityRange: Int? // In meters/feet for proximity verification
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
        deckNumber: Int? = nil,
        locationOnShip: String? = nil,
        section: String? = nil,
        proximityRange: Int? = nil,
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
        self.deckNumber = deckNumber
        self.locationOnShip = locationOnShip
        self.section = section
        self.proximityRange = proximityRange
        self.question = question
        self.answer = answer
        self.order = order
        self.createdAt = Date()
    }
    
    var hasLocation: Bool {
        return deckNumber != nil && locationOnShip != nil
    }
    
    var locationDescription: String {
        var description = ""
        
        if let deck = deckNumber {
            description += "Deck \(deck)"
        }
        
        if let location = locationOnShip {
            if !description.isEmpty {
                description += ", "
            }
            description += location
        }
        
        if let section = section {
            if !description.isEmpty && section.count > 0 {
                description += " ("
                description += section
                description += ")"
            } else if section.count > 0 {
                description += section
            }
        }
        
        return description.isEmpty ? "Location unknown" : description
    }
    
    var isCompleted: Bool {
        guard let completions = completions, !completions.isEmpty else {
            return false
        }
        return completions.contains { $0.isVerified }
    }
} 