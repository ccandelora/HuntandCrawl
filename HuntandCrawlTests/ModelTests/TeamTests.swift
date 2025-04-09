import XCTest
import SwiftData
@testable import HuntandCrawl

class TeamTests: XCTestCase {
    var modelContainer: ModelContainer!
    
    override func setUpWithError() throws {
        // Set up an in-memory container for testing
        let schema = Schema([Team.self, User.self, Hunt.self, BarCrawl.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }
    
    override func tearDownWithError() throws {
        // Clean up
        modelContainer = nil
    }
    
    func testCreateTeam() throws {
        let context = modelContainer.mainContext
        
        // Create a team
        let teamName = "Adventure Squad"
        let teamLogo = "squad_logo".data(using: .utf8)
        let team = Team(name: teamName, logo: teamLogo)
        
        // Insert into context
        context.insert(team)
        
        // Fetch the team
        let descriptor = FetchDescriptor<Team>()
        let teams = try context.fetch(descriptor)
        
        // Verify team was created
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams.first?.name, teamName)
        
        if let savedLogo = teams.first?.logo,
           let logoString = String(data: savedLogo, encoding: .utf8) {
            XCTAssertEqual(logoString, "squad_logo")
        } else {
            XCTFail("Team logo could not be converted back to string")
        }
    }
    
    func testTeamWithMembers() throws {
        let context = modelContainer.mainContext
        
        // Create a team
        let team = Team(name: "Dream Team")
        
        // Create members
        let user1 = User(name: "John", email: "john@example.com")
        let user2 = User(name: "Alice", email: "alice@example.com")
        
        // Insert into context
        context.insert(team)
        context.insert(user1)
        context.insert(user2)
        
        // Add members to team
        team.members = [user1, user2]
        
        // Fetch the team
        let descriptor = FetchDescriptor<Team>()
        let teams = try context.fetch(descriptor)
        
        // Verify team members
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams.first?.members?.count, 2)
        
        let memberNames = teams.first?.members?.map { $0.name } ?? []
        XCTAssertTrue(memberNames.contains("John"))
        XCTAssertTrue(memberNames.contains("Alice"))
    }
    
    func testTeamWithHunts() throws {
        let context = modelContainer.mainContext
        
        // Create a team
        let team = Team(name: "Treasure Hunters")
        
        // Create hunts
        let hunt1 = Hunt(name: "Beach Treasure", huntDescription: "Find treasures on the beach", difficulty: "Easy")
        let hunt2 = Hunt(name: "Mountain Adventure", huntDescription: "Explore the mountains", difficulty: "Hard")
        
        // Insert into context
        context.insert(team)
        context.insert(hunt1)
        context.insert(hunt2)
        
        // Add hunts to team
        team.hunts = [hunt1, hunt2]
        
        // Fetch the team
        let descriptor = FetchDescriptor<Team>()
        let teams = try context.fetch(descriptor)
        
        // Verify team hunts
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams.first?.hunts?.count, 2)
        
        let huntNames = teams.first?.hunts?.map { $0.name } ?? []
        XCTAssertTrue(huntNames.contains("Beach Treasure"))
        XCTAssertTrue(huntNames.contains("Mountain Adventure"))
    }
    
    func testTeamWithBarCrawls() throws {
        let context = modelContainer.mainContext
        
        // Create a team
        let team = Team(name: "Bar Hoppers")
        
        // Create bar crawls
        let barCrawl1 = BarCrawl(name: "Sunset Strip", barCrawlDescription: "Visit bars along the strip", theme: "Tropical")
        let barCrawl2 = BarCrawl(name: "Downtown Dive", barCrawlDescription: "Explore downtown bars", theme: "Classic")
        
        // Insert into context
        context.insert(team)
        context.insert(barCrawl1)
        context.insert(barCrawl2)
        
        // Add bar crawls to team
        team.barCrawls = [barCrawl1, barCrawl2]
        
        // Fetch the team
        let descriptor = FetchDescriptor<Team>()
        let teams = try context.fetch(descriptor)
        
        // Verify team bar crawls
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams.first?.barCrawls?.count, 2)
        
        let barCrawlNames = teams.first?.barCrawls?.map { $0.name } ?? []
        XCTAssertTrue(barCrawlNames.contains("Sunset Strip"))
        XCTAssertTrue(barCrawlNames.contains("Downtown Dive"))
    }
    
    func testUpdateTeam() throws {
        let context = modelContainer.mainContext
        
        // Create a team
        let team = Team(name: "Original Team")
        
        // Insert into context
        context.insert(team)
        
        // Update the team
        let newLogo = "new_logo".data(using: .utf8)
        team.name = "Updated Team"
        team.logo = newLogo
        team.updatedAt = Date()
        
        // Fetch the team
        let descriptor = FetchDescriptor<Team>()
        let teams = try context.fetch(descriptor)
        
        // Verify team was updated
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams.first?.name, "Updated Team")
        
        if let savedLogo = teams.first?.logo,
           let logoString = String(data: savedLogo, encoding: .utf8) {
            XCTAssertEqual(logoString, "new_logo")
        } else {
            XCTFail("Team logo could not be converted back to string")
        }
    }
    
    func testDeleteTeam() throws {
        let context = modelContainer.mainContext
        
        // Create a team
        let team = Team(name: "Team to Delete")
        
        // Insert into context
        context.insert(team)
        
        // Verify it was inserted
        var descriptor = FetchDescriptor<Team>()
        var teams = try context.fetch(descriptor)
        XCTAssertEqual(teams.count, 1)
        
        // Delete the team
        context.delete(team)
        
        // Verify it was deleted
        descriptor = FetchDescriptor<Team>()
        teams = try context.fetch(descriptor)
        XCTAssertEqual(teams.count, 0)
    }
    
    func testTeamAssociations() throws {
        let context = modelContainer.mainContext
        
        // Create a team
        let team = Team(name: "Cruise Explorers")
        
        // Create users, hunts, and bar crawls
        let user = User(name: "Mike", email: "mike@example.com")
        let hunt = Hunt(name: "Ship Exploration", huntDescription: "Explore the cruise ship", difficulty: "Medium")
        let barCrawl = BarCrawl(name: "Deck Bars", barCrawlDescription: "Visit all bars on deck", theme: "Nautical")
        
        // Insert into context
        context.insert(team)
        context.insert(user)
        context.insert(hunt)
        context.insert(barCrawl)
        
        // Set up relationships
        team.members = [user]
        team.hunts = [hunt]
        team.barCrawls = [barCrawl]
        
        // Set up inverse relationships
        user.teams = [team]
        hunt.team = team
        barCrawl.team = team
        
        // Fetch the team
        let teamDescriptor = FetchDescriptor<Team>()
        let teams = try context.fetch(teamDescriptor)
        
        // Verify relationships are maintained
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams.first?.members?.count, 1)
        XCTAssertEqual(teams.first?.hunts?.count, 1)
        XCTAssertEqual(teams.first?.barCrawls?.count, 1)
        
        // Fetch the user
        let userDescriptor = FetchDescriptor<User>()
        let users = try context.fetch(userDescriptor)
        
        // Verify inverse relationship
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.teams?.count, 1)
        XCTAssertEqual(users.first?.teams?.first?.name, "Cruise Explorers")
        
        // Fetch the hunt
        let huntDescriptor = FetchDescriptor<Hunt>()
        let hunts = try context.fetch(huntDescriptor)
        
        // Verify inverse relationship
        XCTAssertEqual(hunts.count, 1)
        XCTAssertEqual(hunts.first?.team?.name, "Cruise Explorers")
        
        // Fetch the bar crawl
        let barCrawlDescriptor = FetchDescriptor<BarCrawl>()
        let barCrawls = try context.fetch(barCrawlDescriptor)
        
        // Verify inverse relationship
        XCTAssertEqual(barCrawls.count, 1)
        XCTAssertEqual(barCrawls.first?.team?.name, "Cruise Explorers")
    }
    
    func testTeamSearching() throws {
        let context = modelContainer.mainContext
        
        // Create teams
        let team1 = Team(name: "Alpha Team")
        let team2 = Team(name: "Beta Team")
        let team3 = Team(name: "Alpha Squad")
        
        // Insert into context
        context.insert(team1)
        context.insert(team2)
        context.insert(team3)
        
        // Search for teams with Alpha in the name
        let alphaDescriptor = FetchDescriptor<Team>(
            predicate: #Predicate { team in
                team.name.contains("Alpha")
            }
        )
        
        let alphaTeams = try context.fetch(alphaDescriptor)
        
        // Verify search results
        XCTAssertEqual(alphaTeams.count, 2)
        
        let alphaTeamNames = alphaTeams.map { $0.name }
        XCTAssertTrue(alphaTeamNames.contains("Alpha Team"))
        XCTAssertTrue(alphaTeamNames.contains("Alpha Squad"))
        XCTAssertFalse(alphaTeamNames.contains("Beta Team"))
    }
} 