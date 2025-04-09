import Foundation
import SwiftData

@Model
final class BarStopVisit {
    var id: String
    var userId: String
    var visitedAt: Date?
    var drinkOrdered: String?
    var rating: Int
    var comments: String?
    var photoData: Data?
    
    @Relationship(deleteRule: .noAction)
    var barStop: BarStop?
    
    @Relationship(deleteRule: .noAction)
    var user: User?
    
    init(
        id: String = UUID().uuidString,
        barStop: BarStop? = nil,
        user: User? = nil,
        userId: String = "",
        visitedAt: Date? = nil,
        drinkOrdered: String? = nil,
        rating: Int = 0,
        comments: String? = nil,
        photoData: Data? = nil
    ) {
        self.id = id
        self.barStop = barStop
        self.user = user
        self.userId = user?.id ?? userId
        self.visitedAt = visitedAt
        self.drinkOrdered = drinkOrdered
        self.rating = rating
        self.comments = comments
        self.photoData = photoData
    }
} 