import XCTest
import SwiftData
@testable import HuntandCrawl

final class TeamModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUpWithError() throws {
        let schema = Schema([
            Team.self,
            User.self,
            Hunt.self,
            BarCrawl.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
    }
    
    override func tearDownWithError() throws {
        clearAllData()
        container = nil
        context = nil
    }
    
    private func clearAllData() {
        // Delete all entities to avoid test interference
        do {
            try context.delete(model: Team.self)
            try context.delete(model: User.self)
            try context.delete(model: Hunt.self)
            try context.delete(model: BarCrawl.self)
        } catch {
            XCTFail("Failed to clear data: \(error)")
        }
        
        try? context.save()
    }
    
    func testCreateTeam() throws {
        // Create a user as creator
        let creator = User(name: "Team Creator")
        context.insert(creator)
        
        // Create a team
        let team = Team(
            name: "Adventure Team",
            creatorId: creator.id
        )
        
        context.insert(team)
        try context.save()
        
        // Fetch the team and verify properties
        let fetchDescriptor = FetchDescriptor<Team>()
        let fetchedTeams = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedTeams.count, 1)
        let fetchedTeam = fetchedTeams.first!
        
        // Verify basic properties
        XCTAssertEqual(fetchedTeam.name, "Adventure Team")
        XCTAssertEqual(fetchedTeam.creatorId, creator.id)
        XCTAssertNil(fetchedTeam.huntId)
        XCTAssertNil(fetchedTeam.barCrawlId)
        XCTAssertEqual(fetchedTeam.score, 0)
        XCTAssertTrue(fetchedTeam.memberIds.isEmpty)
        XCTAssertNotNil(fetchedTeam.createdAt)
        XCTAssertNotNil(fetchedTeam.updatedAt)
    }
    
    func testUpdateTeam() throws {
        // Create a user as creator
        let creator = User(name: "Original Creator")
        context.insert(creator)
        
        // Create a hunt
        let hunt = Hunt(name: "Team Hunt")
        context.insert(hunt)
        
        // Create initial team
        let team = Team(
            name: "Original Team",
            creatorId: creator.id
        )
        
        context.insert(team)
        try context.save()
        
        // Fetch and update the team
        let fetchDescriptor = FetchDescriptor<Team>()
        let fetchedTeams = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedTeams.count, 1)
        
        let fetchedTeam = fetchedTeams.first!
        fetchedTeam.name = "Updated Team"
        fetchedTeam.huntId = hunt.id
        fetchedTeam.score = 100
        fetchedTeam.updatedAt = Date()
        
        try context.save()
        
        // Refetch to verify updates
        let updatedTeams = try context.fetch(fetchDescriptor)
        XCTAssertEqual(updatedTeams.count, 1)
        
        let updatedTeam = updatedTeams.first!
        XCTAssertEqual(updatedTeam.name, "Updated Team")
        XCTAssertEqual(updatedTeam.huntId, hunt.id)
        XCTAssertEqual(updatedTeam.score, 100)
    }
    
    func testDeleteTeam() throws {
        // Create a user as creator
        let creator = User(name: "Team Creator")
        context.insert(creator)
        
        // Create a team
        let team = Team(
            name: "Team to Delete",
            creatorId: creator.id
        )
        
        context.insert(team)
        try context.save()
        
        // Verify team exists
        let fetchDescriptor = FetchDescriptor<Team>()
        var fetchedTeams = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedTeams.count, 1)
        
        // Delete the team
        context.delete(fetchedTeams.first!)
        try context.save()
        
        // Verify team is deleted
        fetchedTeams = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedTeams.count, 0)
        
        // Verify creator still exists
        let userDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == creator.id })
        let users = try context.fetch(userDescriptor)
        XCTAssertEqual(users.count, 1)
    }
    
    func testTeamWithHunt() throws {
        // Create a user as creator
        let creator = User(name: "Hunt Team Creator")
        context.insert(creator)
        
        // Create a hunt
        let hunt = Hunt(
            name: "Team Hunt",
            huntDescription: "Hunt for teams"
        )
        context.insert(hunt)
        
        // Create a team for this hunt
        let team = Team(
            name: "Hunt Team",
            creatorId: creator.id,
            huntId: hunt.id
        )
        
        context.insert(team)
        try context.save()
        
        // Fetch teams for this hunt
        let teamPredicate = #Predicate<Team> { team in
            team.huntId == hunt.id
        }
        
        let teamDescriptor = FetchDescriptor<Team>(predicate: teamPredicate)
        let teams = try context.fetch(teamDescriptor)
        
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams.first?.name, "Hunt Team")
        XCTAssertEqual(teams.first?.huntId, hunt.id)
    }
    
    func testTeamWithBarCrawl() throws {
        // Create a user as creator
        let creator = User(name: "Crawl Team Creator")
        context.insert(creator)
        
        // Create a bar crawl
        let barCrawl = BarCrawl(
            name: "Team Crawl",
            barCrawlDescription: "Crawl for teams"
        )
        context.insert(barCrawl)
        
        // Create a team for this bar crawl
        let team = Team(
            name: "Crawl Team",
            creatorId: creator.id,
            barCrawlId: barCrawl.id
        )
        
        context.insert(team)
        try context.save()
        
        // Fetch teams for this bar crawl
        let teamPredicate = #Predicate<Team> { team in
            team.barCrawlId == barCrawl.id
        }
        
        let teamDescriptor = FetchDescriptor<Team>(predicate: teamPredicate)
        let teams = try context.fetch(teamDescriptor)
        
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams.first?.name, "Crawl Team")
        XCTAssertEqual(teams.first?.barCrawlId, barCrawl.id)
    }
    
    func testTeamMembers() throws {
        // Create users
        let creator = User(name: "Team Leader")
        let member1 = User(name: "Member 1")
        let member2 = User(name: "Member 2")
        
        context.insert(creator)
        context.insert(member1)
        context.insert(member2)
        
        // Create a team with members
        let team = Team(
            name: "Member Team",
            creatorId: creator.id,
            memberIds: [creator.id, member1.id, member2.id]
        )
        
        context.insert(team)
        try context.save()
        
        // Fetch the team and verify members
        let fetchDescriptor = FetchDescriptor<Team>()
        let fetchedTeams = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedTeams.count, 1)
        let fetchedTeam = fetchedTeams.first!
        
        // Verify members
        XCTAssertEqual(fetchedTeam.memberIds.count, 3)
        XCTAssertTrue(fetchedTeam.memberIds.contains(creator.id))
        XCTAssertTrue(fetchedTeam.memberIds.contains(member1.id))
        XCTAssertTrue(fetchedTeam.memberIds.contains(member2.id))
        
        // Add a new member
        let member3 = User(name: "Member 3")
        context.insert(member3)
        
        fetchedTeam.memberIds.append(member3.id)
        try context.save()
        
        // Verify updated members
        let updatedTeamDescriptor = FetchDescriptor<Team>(predicate: #Predicate { $0.id == team.id })
        let updatedTeams = try context.fetch(updatedTeamDescriptor)
        
        XCTAssertEqual(updatedTeams.count, 1)
        let updatedTeam = updatedTeams.first!
        
        XCTAssertEqual(updatedTeam.memberIds.count, 4)
        XCTAssertTrue(updatedTeam.memberIds.contains(member3.id))
    }
    
    func testTeamScore() throws {
        // Create a user as creator
        let creator = User(name: "Score Team Creator")
        context.insert(creator)
        
        // Create a hunt
        let hunt = Hunt(name: "Score Hunt")
        context.insert(hunt)
        
        // Create a team with initial score
        let team = Team(
            name: "Score Team",
            creatorId: creator.id,
            huntId: hunt.id,
            score: 50
        )
        
        context.insert(team)
        try context.save()
        
        // Verify initial score
        let fetchDescriptor = FetchDescriptor<Team>(predicate: #Predicate { $0.id == team.id })
        var fetchedTeams = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedTeams.count, 1)
        var fetchedTeam = fetchedTeams.first!
        XCTAssertEqual(fetchedTeam.score, 50)
        
        // Update score
        fetchedTeam.score += 75
        try context.save()
        
        // Verify updated score
        fetchedTeams = try context.fetch(fetchDescriptor)
        fetchedTeam = fetchedTeams.first!
        XCTAssertEqual(fetchedTeam.score, 125)
    }
    
    func testTeamsCreatedByUser() throws {
        // Create a user who will create multiple teams
        let creator = User(name: "Multiple Teams Creator")
        context.insert(creator)
        
        // Create multiple teams by the same creator
        let team1 = Team(name: "Team 1", creatorId: creator.id)
        let team2 = Team(name: "Team 2", creatorId: creator.id)
        let team3 = Team(name: "Team 3", creatorId: creator.id)
        
        context.insert(team1)
        context.insert(team2)
        context.insert(team3)
        
        try context.save()
        
        // Fetch teams created by this user
        let teamPredicate = #Predicate<Team> { team in
            team.creatorId == creator.id
        }
        
        let teamDescriptor = FetchDescriptor<Team>(predicate: teamPredicate)
        let teams = try context.fetch(teamDescriptor)
        
        XCTAssertEqual(teams.count, 3)
        
        // Verify team names
        let teamNames = teams.map { $0.name }.sorted()
        XCTAssertEqual(teamNames, ["Team 1", "Team 2", "Team 3"])
    }
    
    func testTeamsForHuntAndBarCrawl() throws {
        // Create a user as creator
        let creator = User(name: "Multiple Events Creator")
        context.insert(creator)
        
        // Create a hunt and a bar crawl
        let hunt = Hunt(name: "Multiple Teams Hunt")
        let barCrawl = BarCrawl(name: "Multiple Teams Crawl")
        
        context.insert(hunt)
        context.insert(barCrawl)
        
        // Create teams for hunt
        let huntTeam1 = Team(name: "Hunt Team 1", creatorId: creator.id, huntId: hunt.id)
        let huntTeam2 = Team(name: "Hunt Team 2", creatorId: creator.id, huntId: hunt.id)
        
        // Create teams for bar crawl
        let crawlTeam1 = Team(name: "Crawl Team 1", creatorId: creator.id, barCrawlId: barCrawl.id)
        let crawlTeam2 = Team(name: "Crawl Team 2", creatorId: creator.id, barCrawlId: barCrawl.id)
        
        context.insert(huntTeam1)
        context.insert(huntTeam2)
        context.insert(crawlTeam1)
        context.insert(crawlTeam2)
        
        try context.save()
        
        // Fetch teams for hunt
        let huntTeamPredicate = #Predicate<Team> { team in
            team.huntId == hunt.id
        }
        
        let huntTeamDescriptor = FetchDescriptor<Team>(predicate: huntTeamPredicate)
        let huntTeams = try context.fetch(huntTeamDescriptor)
        
        XCTAssertEqual(huntTeams.count, 2)
        
        // Fetch teams for bar crawl
        let crawlTeamPredicate = #Predicate<Team> { team in
            team.barCrawlId == barCrawl.id
        }
        
        let crawlTeamDescriptor = FetchDescriptor<Team>(predicate: crawlTeamPredicate)
        let crawlTeams = try context.fetch(crawlTeamDescriptor)
        
        XCTAssertEqual(crawlTeams.count, 2)
    }
} 