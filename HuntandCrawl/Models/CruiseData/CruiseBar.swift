import Foundation
import SwiftData

@Model
final class CruiseBar {
    var id: String
    var name: String
    var barDescription: String
    var barType: String
    var signatureDrinks: String
    var atmosphere: String
    var dressCode: String
    var hours: String
    var costCategory: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \CruiseBarDrink.bar)
    var drinks: [CruiseBarDrink]?
    
    @Relationship(deleteRule: .cascade, inverse: \CruiseBarStop.bar)
    var barStops: [CruiseBarStop]?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        barDescription: String,
        barType: String,
        signatureDrinks: String,
        atmosphere: String,
        dressCode: String,
        hours: String,
        costCategory: String
    ) {
        self.id = id
        self.name = name
        self.barDescription = barDescription
        self.barType = barType
        self.signatureDrinks = signatureDrinks
        self.atmosphere = atmosphere
        self.dressCode = dressCode
        self.hours = hours
        self.costCategory = costCategory
        self.createdAt = Date()
    }
}

// MARK: - JSON Import Structure
extension CruiseBar {
    struct ImportJSON: Codable {
        let name: String
        let description: String
        let bar_type: String
        let signature_drinks: String
        let atmosphere: String
        let dress_code: String
        let hours: String
        let cost_category: String
    }
}

// Legacy JSON decoding structs
struct CruiseBarJSON: Decodable {
    let id: Int
    let name: String
    let description: String
    let bar_type: String
    let signature_drinks: String
    let atmosphere: String
    let dress_code: String
    let hours: String
    let cost_category: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, bar_type, signature_drinks, atmosphere, dress_code, hours, cost_category
    }
}

struct CruiseBarsData: Decodable {
    let bars: [CruiseBarJSON]
} 