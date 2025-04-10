import Foundation
import SwiftData

@Model
final class CruiseBarDrink {
    var id: String
    var name: String
    var drinkDescription: String
    var priceRange: String
    var ingredients: String
    var createdAt: Date
    
    @Relationship(deleteRule: .noAction)
    var bar: CruiseBar?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        drinkDescription: String,
        priceRange: String,
        ingredients: String,
        bar: CruiseBar? = nil
    ) {
        self.id = id
        self.name = name
        self.drinkDescription = drinkDescription
        self.priceRange = priceRange
        self.ingredients = ingredients
        self.bar = bar
        self.createdAt = Date()
    }
}

// MARK: - JSON Import Structure
extension CruiseBarDrink {
    struct ImportJSON: Codable {
        let name: String
        let description: String
        let price_range: String
        let ingredients: String
        let bar_id: Int
    }
}

// Legacy JSON decoding structs
struct CruiseBarDrinkJSON: Decodable {
    let id: Int
    let bar_id: Int
    let name: String
    let description: String
    let price_range: String
    let ingredients: String
    
    enum CodingKeys: String, CodingKey {
        case id, bar_id, name, description, price_range, ingredients
    }
}

struct CruiseBarDrinksData: Decodable {
    let bar_drinks: [CruiseBarDrinkJSON]
} 