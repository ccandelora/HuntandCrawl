import Foundation
import SwiftData

@Model
final class CruiseBarStop {
    var id: String
    var locationOnShip: String
    var specialNotes: String
    var createdAt: Date
    
    @Relationship(deleteRule: .noAction)
    var ship: CruiseShip?
    
    @Relationship(deleteRule: .noAction)
    var bar: CruiseBar?
    
    @Relationship(deleteRule: .cascade, inverse: \CruiseBarCrawlStop.barStop)
    var routeStops: [CruiseBarCrawlStop]?
    
    init(
        id: String = UUID().uuidString,
        locationOnShip: String,
        specialNotes: String,
        ship: CruiseShip? = nil,
        bar: CruiseBar? = nil
    ) {
        self.id = id
        self.locationOnShip = locationOnShip
        self.specialNotes = specialNotes
        self.ship = ship
        self.bar = bar
        self.createdAt = Date()
    }
}

// MARK: - JSON Import Structure
extension CruiseBarStop {
    struct ImportJSON: Codable {
        let ship_id: Int
        let bar_id: Int
        let location_on_ship: String
        let special_notes: String
    }
}

// Legacy JSON decoding structs
struct CruiseBarStopJSON: Decodable {
    let id: Int
    let ship_id: Int
    let bar_id: Int
    let location_on_ship: String
    let special_notes: String
    
    enum CodingKeys: String, CodingKey {
        case id, ship_id, bar_id, location_on_ship, special_notes
    }
}

struct CruiseBarStopsData: Decodable {
    let ship_bars: [CruiseBarStopJSON]
} 