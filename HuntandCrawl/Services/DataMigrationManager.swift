import Foundation
import SwiftData

/// Manager class to handle data migrations and database fixes
class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    private init() {}
    
    /// Perform any necessary migrations or data fixes
    func performMigrations(modelContainer: ModelContainer) {
        // Check if we need to migrate Team.memberIds from Array<String> to _memberIdsString
        migrateTeamMemberIds(modelContainer: modelContainer)
    }
    
    /// Migrate team member IDs from array to string-based storage
    private func migrateTeamMemberIds(modelContainer: ModelContainer) {
        // Create a new context for isolated work instead of using mainContext
        let context = ModelContext(modelContainer)
        
        do {
            // Get all teams
            let descriptor = FetchDescriptor<Team>()
            let teams = try context.fetch(descriptor)
            
            // Check if any teams need migration
            var needsSave = false
            
            for team in teams {
                // If memberIds string is empty but this team should have members, try to fix it
                if team._memberIdsString.isEmpty && team.members?.isEmpty == false {
                    // Get member IDs from the actual members relationship
                    let memberIds = team.members?.compactMap { $0.id } ?? []
                    
                    // Set the backing string property directly
                    team._memberIdsString = memberIds.joined(separator: ",")
                    
                    needsSave = true
                    print("Migrated team \(team.name) member IDs")
                }
            }
            
            // Save changes if needed
            if needsSave {
                try context.save()
                print("Successfully migrated team member IDs")
            }
        } catch {
            print("Error migrating team member IDs: \(error.localizedDescription)")
        }
    }
    
    /// Reset the database (dangerous, only for development/testing)
    func resetDatabase(modelContainer: ModelContainer) throws {
        // Create a separate context for deletion
        let context = ModelContext(modelContainer)
        
        // Get all entities
        let teams = try? context.fetch(FetchDescriptor<Team>())
        let users = try? context.fetch(FetchDescriptor<User>())
        let hunts = try? context.fetch(FetchDescriptor<Hunt>())
        let tasks = try? context.fetch(FetchDescriptor<HuntTask>())
        let crawls = try? context.fetch(FetchDescriptor<BarCrawl>())
        let stops = try? context.fetch(FetchDescriptor<BarStop>())
        let visits = try? context.fetch(FetchDescriptor<BarStopVisit>())
        let completions = try? context.fetch(FetchDescriptor<TaskCompletion>())
        
        // Delete all entities
        teams?.forEach { context.delete($0) }
        users?.forEach { context.delete($0) }
        hunts?.forEach { context.delete($0) }
        tasks?.forEach { context.delete($0) }
        crawls?.forEach { context.delete($0) }
        stops?.forEach { context.delete($0) }
        visits?.forEach { context.delete($0) }
        completions?.forEach { context.delete($0) }
        
        // Save changes
        try context.save()
        print("Database has been reset")
    }
} 