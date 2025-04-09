import Foundation
import SwiftData

@Model
class BarStopVisit {
    var id: UUID
    var barStopId: UUID
    var barCrawlId: UUID
    var userId: UUID?
    var teamId: UUID?
    var visitedAt: Date
    var drinkOrdered: String?
    var checkInMethod: String  // "location", "manual", "qrcode", etc.
    var isVerified: Bool
    var verificationData: Data?
    var points: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        barStopId: UUID,
        barCrawlId: UUID,
        userId: UUID? = nil,
        teamId: UUID? = nil,
        visitedAt: Date = Date(),
        drinkOrdered: String? = nil,
        checkInMethod: String,
        isVerified: Bool = false,
        verificationData: Data? = nil,
        points: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.barStopId = barStopId
        self.barCrawlId = barCrawlId
        self.userId = userId
        self.teamId = teamId
        self.visitedAt = visitedAt
        self.drinkOrdered = drinkOrdered
        self.checkInMethod = checkInMethod
        self.isVerified = isVerified
        self.verificationData = verificationData
        self.points = points
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 