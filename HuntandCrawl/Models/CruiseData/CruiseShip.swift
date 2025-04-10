import Foundation
import SwiftData

@Model
final class CruiseShip {
    var id: String
    var name: String
    var shipClass: String
    var yearBuilt: Int
    var passengerCapacity: Int
    var numberOfBars: Int
    var tonnage: Int
    var createdAt: Date
    
    @Relationship(deleteRule: .noAction)
    var cruiseLine: CruiseLine?
    
    @Relationship(deleteRule: .cascade, inverse: \CruiseBarStop.ship)
    var barStops: [CruiseBarStop]?
    
    @Relationship(deleteRule: .cascade, inverse: \CruiseBarCrawlRoute.ship)
    var barCrawlRoutes: [CruiseBarCrawlRoute]?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        shipClass: String,
        yearBuilt: Int,
        passengerCapacity: Int,
        numberOfBars: Int,
        tonnage: Int = 0
    ) {
        self.id = id
        self.name = name
        self.shipClass = shipClass
        self.yearBuilt = yearBuilt
        self.passengerCapacity = passengerCapacity
        self.numberOfBars = numberOfBars
        self.tonnage = tonnage
        self.createdAt = Date()
    }
}

// MARK: - JSON Import Structure
extension CruiseShip {
    struct ImportJSON: Codable {
        let name: String
        let class_name: String
        let year_built: Int
        let passenger_capacity: Int
        let number_of_bars: Int
        let cruise_line_id: Int
        let tonnage: Int?
    }
    
    // Legacy JSON decoding structs - moved inside the CruiseShip extension
    struct LegacyJSON {
        struct CruiseShipJSON: Decodable {
            let id: Int
            let cruise_line_id: Int
            let name: String
            let `class`: String
            let year_built: Int
            let passenger_capacity: Int
            let number_of_bars: Int
            let tonnage: Int?
            
            enum CodingKeys: String, CodingKey {
                case id, cruise_line_id, name, `class`, year_built, passenger_capacity, number_of_bars, tonnage
            }
        }
        
        struct CruiseShipsData: Decodable {
            let ships: [CruiseShipJSON]
        }
    }
} 