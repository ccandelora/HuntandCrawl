import Foundation
import SwiftData

@Model
final class BarCrawl {
    var id: String
    var name: String
    var barCrawlDescription: String?
    var theme: String?
    var startTime: Date?
    var endTime: Date?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date?
    
    @Relationship(deleteRule: .cascade)
    var barStops: [BarStop]?
    
    @Relationship(deleteRule: .noAction)
    var creator: User?
    
    @Relationship(deleteRule: .nullify)
    var teams: [Team]?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        barCrawlDescription: String? = nil,
        theme: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.barCrawlDescription = barCrawlDescription
        self.theme = theme
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = isActive
        self.createdAt = Date()
    }
}

extension BarCrawl {
    var isCompleted: Bool {
        guard let barStops = barStops, !barStops.isEmpty else {
            return false
        }
        return barStops.allSatisfy { $0.isVisited }
    }
    
    var isUpcoming: Bool {
        guard let startTime = startTime else {
            return false
        }
        return startTime > Date()
    }
    
    var isInProgress: Bool {
        guard let startTime = startTime, let endTime = endTime else {
            return isActive
        }
        let now = Date()
        return startTime <= now && now <= endTime && isActive
    }
} 