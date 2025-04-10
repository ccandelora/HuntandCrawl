import Foundation
import SwiftData

@Model
final class CruiseLine {
    var id: String
    var name: String
    var lineDescription: String
    var website: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \CruiseShip.cruiseLine)
    var ships: [CruiseShip]?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        cruiseLineDescription: String = "",
        website: String
    ) {
        self.id = id
        self.name = name
        self.lineDescription = cruiseLineDescription
        self.website = website
        self.createdAt = Date()
    }
    
    // Simplified initializer for use with the ImportJSON struct
    convenience init(name: String, website: String) {
        self.init(
            name: name,
            cruiseLineDescription: "",
            website: website
        )
    }
}

// MARK: - Example Data
extension CruiseLine {
    static var example: CruiseLine {
        let cruiseLine = CruiseLine(
            name: "Royal Caribbean",
            cruiseLineDescription: "Award-winning cruise line with innovative ships",
            website: "www.royalcaribbean.com"
        )
        return cruiseLine
    }
}

// MARK: - JSON Import Structure
extension CruiseLine {
    struct ImportJSON: Codable {
        let name: String
        let description: String?
        let website: String
    }
    
    // Legacy JSON decoding structs - moved inside the CruiseLine extension
    struct LegacyJSON {
        struct CruiseLineJSON: Decodable {
            let id: Int
            let name: String
            let description: String
            let website: String
            
            enum CodingKeys: String, CodingKey {
                case id, name, description, website
            }
        }
        
        struct CruiseLinesData: Decodable {
            let cruise_lines: [CruiseLineJSON]
        }
    }
} 