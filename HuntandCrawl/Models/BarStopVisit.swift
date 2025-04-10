import Foundation
import SwiftData

@Model
final class BarStopVisit {
    var id: String
    var visitedAt: Date
    var drinkOrdered: String?
    var rating: Int
    var comments: String?
    var createdAt: Date
    var updatedAt: Date
    var photoData: Data?
    
    @Relationship(deleteRule: .noAction)
    var barStop: BarStop?
    
    @Relationship(deleteRule: .noAction)
    var user: User?
    
    init(
        id: String = UUID().uuidString,
        visitedAt: Date,
        photoData: Data? = nil,
        drinkOrdered: String? = nil,
        rating: Int = 0,
        comments: String? = nil,
        barStop: BarStop? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.visitedAt = visitedAt
        self.photoData = photoData
        self.drinkOrdered = drinkOrdered
        self.rating = rating
        self.comments = comments
        self.barStop = barStop
        self.user = user
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// Add this typealias to support the Visit model references
typealias Visit = BarStopVisit 