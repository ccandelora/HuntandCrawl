import Foundation
import SwiftData

@Model
final class BarStop {
    var id: UUID
    var name: String
    var descriptionText: String
    var location: String
    var deckNumber: Int?
    var specialDrink: String
    var drinkPrice: Double?
    var openingTime: Date?
    var closingTime: Date?
    var activity: String?
    var order: Int
    var visitTime: Date?
    var isVisited: Bool
    var imageRequired: Bool
    var image: Data?
    var isVIP: Bool
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String,
        location: String,
        deckNumber: Int? = nil,
        specialDrink: String,
        drinkPrice: Double? = nil,
        openingTime: Date? = nil,
        closingTime: Date? = nil,
        activity: String? = nil,
        order: Int = 0,
        visitTime: Date? = nil,
        isVisited: Bool = false,
        imageRequired: Bool = true,
        image: Data? = nil,
        isVIP: Bool = false,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.location = location
        self.deckNumber = deckNumber
        self.specialDrink = specialDrink
        self.drinkPrice = drinkPrice
        self.openingTime = openingTime
        self.closingTime = closingTime
        self.activity = activity
        self.order = order
        self.visitTime = visitTime
        self.isVisited = isVisited
        self.imageRequired = imageRequired
        self.image = image
        self.isVIP = isVIP
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 