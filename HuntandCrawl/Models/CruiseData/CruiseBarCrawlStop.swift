import Foundation
import SwiftData

@Model
final class CruiseBarCrawlStop {
    var id: String
    var stopOrder: Int
    var recommendedDrink: String
    var timeToSpend: String
    var stopNotes: String
    var createdAt: Date
    
    @Relationship(deleteRule: .noAction)
    var route: CruiseBarCrawlRoute?
    
    @Relationship(deleteRule: .noAction)
    var barStop: CruiseBarStop?
    
    init(
        id: String = UUID().uuidString,
        stopOrder: Int,
        recommendedDrink: String,
        timeToSpend: String,
        stopNotes: String = "",
        route: CruiseBarCrawlRoute? = nil,
        barStop: CruiseBarStop? = nil
    ) {
        self.id = id
        self.stopOrder = stopOrder
        self.recommendedDrink = recommendedDrink
        self.timeToSpend = timeToSpend
        self.stopNotes = stopNotes
        self.route = route
        self.barStop = barStop
        self.createdAt = Date()
    }
}

// MARK: - JSON Import Structure
extension CruiseBarCrawlStop {
    struct ImportJSON: Codable {
        let route_id: Int
        let bar_id: Int
        let stop_order: Int
        let recommended_drink: String
        let time_to_spend: String
        let stop_notes: String?
    }
}

// Legacy JSON decoding structs
struct CruiseBarCrawlStopJSON: Decodable {
    let id: Int
    let route_id: Int
    let bar_id: Int
    let stop_order: Int
    let recommended_drink: String
    let time_to_spend: String
    
    enum CodingKeys: String, CodingKey {
        case id, route_id, bar_id, stop_order, recommended_drink, time_to_spend
    }
}

struct CruiseBarCrawlStopsData: Decodable {
    let route_stops: [CruiseBarCrawlStopJSON]
} 