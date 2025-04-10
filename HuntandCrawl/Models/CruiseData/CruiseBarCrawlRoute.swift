import Foundation
import SwiftData

@Model
final class CruiseBarCrawlRoute {
    var id: String
    var name: String
    var routeDescription: String
    var estimatedDuration: String
    var difficultyLevel: String
    var numberOfStops: Int
    var createdAt: Date
    
    @Relationship(deleteRule: .noAction)
    var ship: CruiseShip?
    
    @Relationship(deleteRule: .cascade, inverse: \CruiseBarCrawlStop.route)
    var stops: [CruiseBarCrawlStop]?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        routeDescription: String,
        estimatedDuration: String,
        difficultyLevel: String,
        numberOfStops: Int,
        ship: CruiseShip? = nil
    ) {
        self.id = id
        self.name = name
        self.routeDescription = routeDescription
        self.estimatedDuration = estimatedDuration
        self.difficultyLevel = difficultyLevel
        self.numberOfStops = numberOfStops
        self.ship = ship
        self.createdAt = Date()
    }
}

// MARK: - JSON Import Structure
extension CruiseBarCrawlRoute {
    struct ImportJSON: Codable {
        let name: String
        let description: String
        let estimated_duration: String
        let difficulty_level: String
        let number_of_stops: Int
        let ship_id: Int
    }
}

// Legacy JSON decoding structs
struct CruiseBarCrawlRouteJSON: Decodable {
    let id: Int
    let ship_id: Int
    let name: String
    let description: String
    let estimated_duration: String
    let difficulty_level: String
    let number_of_stops: Int
    
    enum CodingKeys: String, CodingKey {
        case id, ship_id, name, description, estimated_duration, difficulty_level, number_of_stops
    }
}

struct CruiseBarCrawlRoutesData: Decodable {
    let bar_crawl_routes: [CruiseBarCrawlRouteJSON]
} 