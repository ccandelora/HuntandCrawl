import Foundation
import SwiftData
import Combine

// MARK: - JSON Data Structures
// These structures directly match the JSON format in the cruise_database folder

struct CruiseLineJSONData: Codable {
    let id: Int
    let name: String
    let description: String
    let website: String
}

struct CruiseLinesJSONData: Codable {
    let cruise_lines: [CruiseLineJSONData]
}

struct ShipJSON: Codable {
    let id: Int
    let cruise_line_id: Int
    let name: String
    let `class`: String
    let year_built: Int
    let passenger_capacity: Int
    let number_of_bars: Int
    let tonnage: Int?
}

struct ShipsData: Codable {
    let ships: [ShipJSON]
}

struct BarJSON: Codable {
    let id: Int
    let name: String
    let description: String
    let bar_type: String
    let signature_drinks: String
    let atmosphere: String
    let dress_code: String
    let hours: String
    let cost_category: String
}

struct BarsData: Codable {
    let bars: [BarJSON]
}

struct ShipBarJSON: Codable {
    let id: Int
    let ship_id: Int
    let bar_id: Int
    let location_on_ship: String
    let special_notes: String
}

struct ShipBarsData: Codable {
    let ship_bars: [ShipBarJSON]
}

struct BarCrawlRouteJSON: Codable {
    let id: Int
    let ship_id: Int
    let name: String
    let description: String
    let estimated_duration: String
    let difficulty_level: String
    let number_of_stops: Int
}

struct BarCrawlRoutesData: Codable {
    let bar_crawl_routes: [BarCrawlRouteJSON]
}

struct RouteStopJSON: Codable {
    let id: Int
    let route_id: Int
    let bar_id: Int
    let stop_order: Int
    let recommended_drink: String
    let time_to_spend: String
}

struct RouteStopsData: Codable {
    let route_stops: [RouteStopJSON]
}

// MARK: - CruiseDataService
class CruiseDataService {
    static let shared = CruiseDataService()
    
    private init() {}
    
    /// Load all cruise data in the correct order (cruise lines first, then ships, etc.)
    func loadAllData(into context: ModelContext, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var success = true
            
            // Load cruise lines first
            if !self.loadCruiseLines(into: context) {
                success = false
            }
            
            // Load cruise ships
            if !self.loadCruiseShips(into: context) {
                success = false
            }
            
            // Load cruise bars
            if !self.loadCruiseBars(into: context) {
                success = false
            }
            
            // Load cruise bar stops
            if !self.loadCruiseBarStops(into: context) {
                success = false
            }
            
            // Load cruise bar crawl routes and stops
            if !self.loadCruiseBarCrawlRoutes(into: context) {
                success = false
            }
            
            DispatchQueue.main.async {
                try? context.save()
                completion(success)
            }
        }
    }
    
    // MARK: - Loading Cruise Lines
    private func loadCruiseLines(into context: ModelContext) -> Bool {
        guard let cruiseLinesData = loadJSON(from: "cruise_database/database_structure/cruise_lines.json") else {
            print("Failed to load cruise lines data")
            return false
        }
        
        do {
            let cruiseLines = try JSONDecoder().decode([CruiseLineJSONData].self, from: cruiseLinesData)
            
            for lineData in cruiseLines {
                let cruiseLine = CruiseLine(
                    id: UUID().uuidString,
                    name: lineData.name,
                    cruiseLineDescription: lineData.description,
                    website: lineData.website
                )
                cruiseLine.sourceId = String(lineData.id)
                context.insert(cruiseLine)
            }
            
            print("Loaded \(cruiseLines.count) cruise lines")
            return true
        } catch {
            print("Error decoding cruise lines: \(error)")
            return false
        }
    }
    
    // MARK: - Loading Cruise Ships
    private func loadCruiseShips(into context: ModelContext) -> Bool {
        guard let shipsData = loadJSON(from: "cruise_database/database_structure/ships.json") else {
            print("Failed to load ships data")
            return false
        }
        
        do {
            let ships = try JSONDecoder().decode([ShipJSON].self, from: shipsData)
            
            // Get cruise lines to link to ships
            let descriptor = FetchDescriptor<CruiseLine>()
            let cruiseLines = try context.fetch(descriptor)
            
            for shipData in ships {
                // Find the cruise line for this ship
                guard let cruiseLine = cruiseLines.first(where: { $0.sourceId == String(shipData.cruise_line_id) }) else {
                    print("Could not find cruise line for ship: \(shipData.name)")
                    continue
                }
                
                let cruiseShip = CruiseShip(
                    id: UUID().uuidString,
                    name: shipData.name,
                    shipClass: shipData.class,
                    yearBuilt: shipData.year_built,
                    passengerCapacity: shipData.passenger_capacity,
                    numberOfBars: shipData.number_of_bars,
                    tonnage: shipData.tonnage ?? 0
                )
                cruiseShip.sourceId = String(shipData.id)
                cruiseShip.cruiseLine = cruiseLine
                context.insert(cruiseShip)
            }
            
            print("Loaded \(ships.count) cruise ships")
            return true
        } catch {
            print("Error decoding cruise ships: \(error)")
            return false
        }
    }
    
    // MARK: - Loading Cruise Bars
    private func loadCruiseBars(into context: ModelContext) -> Bool {
        guard let barsData = loadJSON(from: "cruise_database/database_structure/bars.json") else {
            print("Failed to load bars data")
            return false
        }
        
        do {
            let bars = try JSONDecoder().decode([BarJSON].self, from: barsData)
            
            for barData in bars {
                let cruiseBar = CruiseBar(
                    id: UUID().uuidString,
                    name: barData.name,
                    barDescription: barData.description,
                    barType: barData.bar_type,
                    signatureDrinks: barData.signature_drinks,
                    atmosphere: barData.atmosphere,
                    dressCode: barData.dress_code,
                    hours: barData.hours,
                    costCategory: barData.cost_category
                )
                cruiseBar.sourceId = String(barData.id)
                context.insert(cruiseBar)
            }
            
            print("Loaded \(bars.count) cruise bars")
            return true
        } catch {
            print("Error decoding cruise bars: \(error)")
            return false
        }
    }
    
    // MARK: - Loading Cruise Bar Stops
    private func loadCruiseBarStops(into context: ModelContext) -> Bool {
        guard let barStopsData = loadJSON(from: "cruise_database/database_structure/bar_stops.json") else {
            print("Failed to load bar stops data")
            return false
        }
        
        do {
            let barStops = try JSONDecoder().decode([ShipBarJSON].self, from: barStopsData)
            
            // Get cruise ships and bars to link
            let shipDescriptor = FetchDescriptor<CruiseShip>()
            let cruiseShips = try context.fetch(shipDescriptor)
            
            let barDescriptor = FetchDescriptor<CruiseBar>()
            let cruiseBars = try context.fetch(barDescriptor)
            
            for stopData in barStops {
                // Find the ship and bar for this stop
                guard let ship = cruiseShips.first(where: { $0.sourceId == String(stopData.ship_id) }) else {
                    print("Could not find ship for bar stop: \(stopData.id)")
                    continue
                }
                
                guard let bar = cruiseBars.first(where: { $0.sourceId == String(stopData.bar_id) }) else {
                    print("Could not find bar for bar stop: \(stopData.id)")
                    continue
                }
                
                let shipBar = CruiseBarStop(
                    id: UUID().uuidString,
                    locationOnShip: stopData.location_on_ship,
                    specialNotes: stopData.special_notes
                )
                shipBar.sourceId = String(stopData.id)
                shipBar.ship = ship
                shipBar.bar = bar
                context.insert(shipBar)
            }
            
            print("Loaded \(barStops.count) cruise bar stops")
            return true
        } catch {
            print("Error decoding cruise bar stops: \(error)")
            return false
        }
    }
    
    // MARK: - Loading Cruise Bar Crawl Routes
    private func loadCruiseBarCrawlRoutes(into context: ModelContext) -> Bool {
        guard let routesData = loadJSON(from: "cruise_database/database_structure/bar_crawl_routes.json") else {
            print("Failed to load bar crawl routes data")
            return false
        }
        
        do {
            let routes = try JSONDecoder().decode([BarCrawlRouteJSON].self, from: routesData)
            
            // Get cruise ships to link
            let shipDescriptor = FetchDescriptor<CruiseShip>()
            let cruiseShips = try context.fetch(shipDescriptor)
            
            for routeData in routes {
                // Find the ship for this route
                guard let ship = cruiseShips.first(where: { $0.sourceId == String(routeData.ship_id) }) else {
                    print("Could not find ship for bar crawl route: \(routeData.name)")
                    continue
                }
                
                let route = CruiseBarCrawlRoute(
                    id: UUID().uuidString,
                    name: routeData.name,
                    routeDescription: routeData.description,
                    estimatedDuration: routeData.estimated_duration,
                    difficultyLevel: routeData.difficulty_level,
                    numberOfStops: routeData.number_of_stops,
                    ship: ship
                )
                route.sourceId = String(routeData.id)
                context.insert(route)
                
                // Load the stops for this route
                loadCruiseBarCrawlStops(for: route, routeData: routeData, context: context)
            }
            
            print("Loaded \(routes.count) cruise bar crawl routes")
            return true
        } catch {
            print("Error decoding cruise bar crawl routes: \(error)")
            return false
        }
    }
    
    // Helper to load the stops for a specific route
    private func loadCruiseBarCrawlStops(for route: CruiseBarCrawlRoute, routeData: BarCrawlRouteJSON, context: ModelContext) {
        guard let stopsData = loadJSON(from: "cruise_database/database_structure/bar_crawl_stops.json") else {
            print("Failed to load bar crawl stops data")
            return
        }
        
        do {
            let allStops = try JSONDecoder().decode([RouteStopJSON].self, from: stopsData)
            
            // Filter stops for this route
            let routeStops = allStops.filter { $0.route_id == routeData.id }
            
            for stopData in routeStops {
                // Find the bar stop for this crawl stop
                // Convert the bar_id to string outside the predicate
                let barId = stopData.bar_id.description
                
                // First try to find the bar by direct ID match
                let barDescriptor = FetchDescriptor<CruiseBar>(
                    predicate: #Predicate { bar in 
                        bar.id == barId
                    }
                )
                
                 var bars = try context.fetch(barDescriptor)
                
                // If not found by ID, try using sourceId (stored in UserDefaults)
                if bars.isEmpty {
                    // Fetch all bars and filter manually since sourceId is @Transient
                    let allBarsDescriptor = FetchDescriptor<CruiseBar>()
                    let allBars = try context.fetch(allBarsDescriptor)
                    bars = allBars.filter { $0.sourceId == barId }
                }
                
                guard let bar = bars.first else {
                    print("Could not find bar with ID \(stopData.bar_id)")
                    continue
                }
                
                // First we need to find or create a CruiseBarStop for the bar
                let barStopDescriptor = FetchDescriptor<CruiseBarStop>()
                
                let allBarStops = try context.fetch(barStopDescriptor)
                // Filter manually in Swift code
                let matchingBarStops = allBarStops.filter { barStop in
                    guard let stopBar = barStop.bar else { return false }
                    return stopBar.id == bar.id
                }
                
                let barStop: CruiseBarStop
                
                if let existingBarStop = matchingBarStops.first {
                    barStop = existingBarStop
                } else {
                    // Create a new bar stop for this bar
                    barStop = CruiseBarStop(
                        id: UUID().uuidString,
                        locationOnShip: "Deck \(Int.random(in: 1...18))", // Random deck placement
                        specialNotes: "",
                        ship: route.ship,
                        bar: bar
                    )
                    context.insert(barStop)
                }
                
                let routeStop = CruiseBarCrawlStop(
                    id: UUID().uuidString,
                    stopOrder: stopData.stop_order,
                    recommendedDrink: stopData.recommended_drink,
                    timeToSpend: stopData.time_to_spend,
                    stopNotes: "",
                    route: route,
                    barStop: barStop
                )
                routeStop.sourceId = String(stopData.id)
                context.insert(routeStop)
            }
            
            print("Loaded \(routeStops.count) stops for route: \(route.name)")
        } catch {
            print("Error decoding cruise bar crawl stops: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    
    /// Load JSON data from a file in the app bundle
    private func loadJSON(from filePath: String) -> Data? {
        guard let fileURL = Bundle.main.url(forResource: filePath, withExtension: nil) else {
            print("Could not find file at path: \(filePath)")
            return nil
        }
        
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            print("Error loading JSON from \(filePath): \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractDeckNumber(from location: String) -> Int? {
        // Example: "Deck 6, Promenade" should return 6
        let pattern = "Deck (\\d+)"
        let regex = try? NSRegularExpression(pattern: pattern)
        
        if let match = regex?.firstMatch(in: location, range: NSRange(location: 0, length: location.count)) {
            if let range = Range(match.range(at: 1), in: location) {
                return Int(location[range])
            }
        }
        
        return nil
    }
    
    private func extractSection(from location: String) -> String? {
        // Example locations might contain Forward, Midship, or Aft sections
        let sections = ["Forward", "Midship", "Aft"]
        
        for section in sections {
            if location.contains(section) {
                return section
            }
        }
        
        return nil
    }
}

// MARK: - Model Extensions
// Add sourceId property to models to track original JSON ID

extension CruiseLine {
    @Transient
    var sourceId: String? {
        get { UserDefaults.standard.string(forKey: "CruiseLine_\(id)_sourceId") }
        set { UserDefaults.standard.set(newValue, forKey: "CruiseLine_\(id)_sourceId") }
    }
}

extension CruiseShip {
    @Transient
    var sourceId: String? {
        get { UserDefaults.standard.string(forKey: "CruiseShip_\(id)_sourceId") }
        set { UserDefaults.standard.set(newValue, forKey: "CruiseShip_\(id)_sourceId") }
    }
}

extension CruiseBar {
    @Transient
    var sourceId: String? {
        get { UserDefaults.standard.string(forKey: "CruiseBar_\(id)_sourceId") }
        set { UserDefaults.standard.set(newValue, forKey: "CruiseBar_\(id)_sourceId") }
    }
}

extension CruiseBarStop {
    @Transient
    var sourceId: String? {
        get { UserDefaults.standard.string(forKey: "CruiseBarStop_\(id)_sourceId") }
        set { UserDefaults.standard.set(newValue, forKey: "CruiseBarStop_\(id)_sourceId") }
    }
}

extension BarCrawl {
    @Transient
    var sourceId: String? {
        get { UserDefaults.standard.string(forKey: "BarCrawl_\(id)_sourceId") }
        set { UserDefaults.standard.set(newValue, forKey: "BarCrawl_\(id)_sourceId") }
    }
}

extension CruiseBarCrawlStop {
    @Transient
    var sourceId: String? {
        get { UserDefaults.standard.string(forKey: "CruiseBarCrawlStop_\(id)_sourceId") }
        set { UserDefaults.standard.set(newValue, forKey: "CruiseBarCrawlStop_\(id)_sourceId") }
    }
}

extension CruiseBarCrawlRoute {
    @Transient
    var sourceId: String? {
        get { UserDefaults.standard.string(forKey: "CruiseBarCrawlRoute_\(id)_sourceId") }
        set { UserDefaults.standard.set(newValue, forKey: "CruiseBarCrawlRoute_\(id)_sourceId") }
    }
} 
