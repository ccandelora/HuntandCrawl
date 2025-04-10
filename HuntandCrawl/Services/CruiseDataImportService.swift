import Foundation
import SwiftData

class CruiseDataImportService {
    static let shared = CruiseDataImportService()
    
    public init() {}
    
    func importAllCruiseData(modelContext: ModelContext) async throws {
        try await importCruiseLines(modelContext: modelContext)
        try await importCruiseShips(modelContext: modelContext)
        try await importCruiseBars(modelContext: modelContext)
        try await importCruiseBarCrawlRoutes(modelContext: modelContext)
    }
    
    private func importCruiseLines(modelContext: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: "cruise_lines", withExtension: "json", subdirectory: "cruise_database/database_structure") else {
            throw ImportError.fileNotFound(name: "cruise_lines.json")
        }
        
        let data = try Data(contentsOf: url)
        let cruiseLines = try JSONDecoder().decode([CruiseLine.ImportJSON].self, from: data)
        
        for cruiseLineData in cruiseLines {
            let cruiseLine = CruiseLine(
                name: cruiseLineData.name,
                website: cruiseLineData.website
            )
            modelContext.insert(cruiseLine)
        }
        
        try modelContext.save()
    }
    
    private func importCruiseShips(modelContext: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: "ships", withExtension: "json", subdirectory: "cruise_database/database_structure") else {
            throw ImportError.fileNotFound(name: "ships.json")
        }
        
        let data = try Data(contentsOf: url)
        let shipsData = try JSONDecoder().decode([CruiseShip.ImportJSON].self, from: data)
        
        // Fetch existing cruise lines to link ships
        let descriptor = FetchDescriptor<CruiseLine>()
        let cruiseLines = try modelContext.fetch(descriptor)
        
        for shipData in shipsData {
            // Find the cruise line to link this ship to by ID
            guard let cruiseLine = cruiseLines.first(where: { $0.sourceId == String(shipData.cruise_line_id) }) else {
                print("Could not find cruise line with ID \(shipData.cruise_line_id)")
                continue
            }
            
            let ship = CruiseShip(
                name: shipData.name,
                shipClass: shipData.class_name,
                yearBuilt: shipData.year_built,
                passengerCapacity: shipData.passenger_capacity,
                numberOfBars: shipData.number_of_bars,
                tonnage: shipData.tonnage ?? 0
            )
            
            ship.cruiseLine = cruiseLine
            modelContext.insert(ship)
        }
        
        try modelContext.save()
    }
    
    private func importCruiseBars(modelContext: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: "bars", withExtension: "json", subdirectory: "cruise_database/database_structure") else {
            throw ImportError.fileNotFound(name: "bars.json")
        }
        
        let data = try Data(contentsOf: url)
        let barsData = try JSONDecoder().decode([CruiseBar.ImportJSON].self, from: data)
        
        for barData in barsData {
            let bar = CruiseBar(
                name: barData.name,
                barDescription: barData.description,
                barType: barData.bar_type,
                signatureDrinks: barData.signature_drinks,
                atmosphere: barData.atmosphere,
                dressCode: barData.dress_code,
                hours: barData.hours,
                costCategory: barData.cost_category
            )
            
            modelContext.insert(bar)
        }
        
        try modelContext.save()
    }
    
    private func importCruiseBarCrawlRoutes(modelContext: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: "bar_crawl_routes", withExtension: "json", subdirectory: "cruise_database/database_structure") else {
            throw ImportError.fileNotFound(name: "bar_crawl_routes.json")
        }
        
        let data = try Data(contentsOf: url)
        let routesData = try JSONDecoder().decode([CruiseBarCrawlRoute.ImportJSON].self, from: data)
        
        // Fetch existing ships to link routes
        let shipsDescriptor = FetchDescriptor<CruiseShip>()
        let ships = try modelContext.fetch(shipsDescriptor)
        
        for routeData in routesData {
            // Find the ship this route belongs to by ID
            guard let ship = ships.first(where: { $0.sourceId == String(routeData.ship_id) }) else {
                print("Could not find ship with ID \(routeData.ship_id)")
                continue
            }
            
            let route = CruiseBarCrawlRoute(
                name: routeData.name,
                routeDescription: routeData.description,
                estimatedDuration: routeData.estimated_duration,
                difficultyLevel: routeData.difficulty_level,
                numberOfStops: routeData.number_of_stops,
                ship: ship
            )
            
            modelContext.insert(route)
        }
        
        try modelContext.save()
    }
    
    enum ImportError: Error {
        case fileNotFound(name: String)
        case dataParsingError
    }
} 