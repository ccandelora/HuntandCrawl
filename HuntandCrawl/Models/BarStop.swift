import Foundation
import SwiftData
import CoreLocation

@Model
final class BarStop {
    var id: String
    var name: String
    var barStopDescription: String?
    var specialDrink: String?
    var drinkPrice: Double
    var checkInRadius: Double
    var latitude: Double?
    var longitude: Double?
    var openingTime: Date?
    var closingTime: Date?
    var order: Int
    var isVIP: Bool
    var createdAt: Date
    var updatedAt: Date?
    
    @Relationship(deleteRule: .cascade)
    var visits: [BarStopVisit]?
    
    @Relationship(deleteRule: .noAction)
    var barCrawl: BarCrawl?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        specialDrink: String? = nil,
        drinkPrice: Double,
        barStopDescription: String? = nil,
        checkInRadius: Double = 50,
        latitude: Double? = nil,
        longitude: Double? = nil,
        openingTime: Date? = nil,
        closingTime: Date? = nil,
        order: Int = 0,
        isVIP: Bool = false
    ) {
        self.id = id
        self.name = name
        self.barStopDescription = barStopDescription
        self.specialDrink = specialDrink
        self.drinkPrice = drinkPrice
        self.checkInRadius = checkInRadius
        self.latitude = latitude
        self.longitude = longitude
        self.openingTime = openingTime
        self.closingTime = closingTime
        self.order = order
        self.isVIP = isVIP
        self.createdAt = Date()
    }
}

extension BarStop {
    var hasLocation: Bool {
        return latitude != nil && longitude != nil
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isOpen: Bool {
        guard let openingTime = openingTime, let closingTime = closingTime else {
            return true // If no times specified, assume always open
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Get hours and minutes components
        let openComponents = calendar.dateComponents([.hour, .minute], from: openingTime)
        let closeComponents = calendar.dateComponents([.hour, .minute], from: closingTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        guard let openHour = openComponents.hour, let openMinute = openComponents.minute,
              let closeHour = closeComponents.hour, let closeMinute = closeComponents.minute,
              let currentHour = currentComponents.hour, let currentMinute = currentComponents.minute else {
            return true
        }
        
        // Convert to minutes since midnight for easier comparison
        let openMinutes = openHour * 60 + openMinute
        let closeMinutes = closeHour * 60 + closeMinute
        let currentMinutes = currentHour * 60 + currentMinute
        
        // Handle case where closing time is on the next day (e.g., 2am)
        if closeMinutes < openMinutes {
            return currentMinutes >= openMinutes || currentMinutes <= closeMinutes
        } else {
            return currentMinutes >= openMinutes && currentMinutes <= closeMinutes
        }
    }
    
    var isVisited: Bool {
        guard let visits = visits, !visits.isEmpty else {
            return false
        }
        return true
    }
} 