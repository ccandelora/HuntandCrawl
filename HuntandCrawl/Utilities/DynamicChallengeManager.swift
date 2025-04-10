import Foundation
import SwiftData
import Combine
import CoreLocation

class DynamicChallengeManager: ObservableObject {
    private var modelContext: ModelContext
    private var locationManager: LocationManager?
    
    // Published properties
    @Published var pendingChallenges: [HuntTask] = []
    @Published var lastChallengeGeneratedAt: Date?
    @Published var isGeneratingChallenge = false
    
    // Minimum requirements for challenge generation
    private let minimumTeamMembersRequired = 2
    private let challengeCooldownPeriod: TimeInterval = 1800 // 30 minutes
    
    // Store challenge templates
    private let challengeTemplates = [
        "Take a group selfie with all team members visible",
        "Create a human pyramid with your team",
        "Perform a synchronized dance and record it",
        "Each team member must share one interesting fact about themselves",
        "Do a conga line through the cruise ship",
        "Create the ship's logo or name using your bodies",
        "Perform a group karaoke song",
        "Take a group photo with a crew member",
        "Have each team member record a 5-second video sharing their favorite moment so far",
        "Have the team create a short cheer or chant about the cruise"
    ]
    
    var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext, locationManager: LocationManager? = nil) {
        self.modelContext = modelContext
        self.locationManager = locationManager
    }
    
    // Generate a team challenge
    func generateTeamChallenge(for hunt: Hunt, teamId: String) -> AnyPublisher<HuntTask, Error> {
        return Future<HuntTask, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DynamicChallengeManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return
            }
            
            // Check cooldown period
            if let lastGenerated = self.lastChallengeGeneratedAt,
               Date().timeIntervalSince(lastGenerated) < self.challengeCooldownPeriod {
                promise(.failure(NSError(domain: "DynamicChallengeManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Challenge generation is on cooldown"])))
                return
            }
            
            // Start challenge generation
            self.isGeneratingChallenge = true
            
            // Select a random challenge template
            let challengeTemplate = self.challengeTemplates.randomElement() ?? "Team Challenge"
            let challengeTitle = "Team Challenge: " + challengeTemplate
            
            // Add team and time metadata as subtitle
            let metadataNote = """
            Team Challenge:
            - Team ID: \(teamId)
            - Generated: \(Date().formatted())
            - Expires: \(Date().addingTimeInterval(3600).formatted())
            - Requires \(self.minimumTeamMembersRequired) team members
            """
            
            // Create the challenge task with proper parameters
            let task = HuntTask(
                title: challengeTitle,
                subtitle: metadataNote,
                taskDescription: "Complete this challenge with your team members!",
                points: Int.random(in: 50...150),
                verificationMethod: .photo,
                deckNumber: Int.random(in: 7...15), // Random deck for cruise ship challenge
                locationOnShip: ["Main Dining", "Pool Deck", "Theater", "Casino", "Buffet"].randomElement() ?? "Main Lobby",
                section: ["Forward", "Midship", "Aft"].randomElement() ?? "Midship",
                order: (hunt.tasks?.count ?? 0) + 1
            )
            
            // Set hunt relationship
            task.hunt = hunt
            
            // Add it to the hunt
            hunt.tasks?.append(task)
            self.modelContext.insert(task)
            
            do {
                try self.modelContext.save()
                
                // Add to pending challenges
                self.pendingChallenges.append(task)
                
                // Update last generated timestamp
                self.lastChallengeGeneratedAt = Date()
                
                // Complete challenge generation
                self.isGeneratingChallenge = false
                
                promise(.success(task))
            } catch {
                self.isGeneratingChallenge = false
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Check if a challenge is eligible for completion
    func isEligibleForCompletion(task: HuntTask) -> Bool {
        // Parse metadata from subtitle to check dynamic status, expiration, etc.
        guard let subtitle = task.subtitle,
              subtitle.contains("Team Challenge:"),
              !isExpired(task: task) else {
            return false
        }
        
        // For now, we don't enforce team member proximity without Bluetooth
        // Just check if the task is within its time window
        return true
    }
    
    // Helper function to check if task is expired based on metadata
    private func isExpired(task: HuntTask) -> Bool {
        guard let subtitle = task.subtitle else { return false }
        
        // Extract expiration time from metadata
        if let expiresRange = subtitle.range(of: "Expires: ") {
            let expiresStart = expiresRange.upperBound
            if let endOfLine = subtitle[expiresStart...].firstIndex(of: "\n") {
                let expiresString = String(subtitle[expiresStart..<endOfLine])
                
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                
                if let expiresDate = formatter.date(from: expiresString) {
                    return Date() > expiresDate
                }
            }
        }
        
        return false // Default to not expired if can't determine
    }
    
    // Get team ID from task metadata
    private func getTeamId(from task: HuntTask) -> String? {
        guard let subtitle = task.subtitle else { return nil }
        
        // Extract team ID from metadata
        if let teamIdRange = subtitle.range(of: "Team ID: ") {
            let teamIdStart = teamIdRange.upperBound
            if let endOfLine = subtitle[teamIdStart...].firstIndex(of: "\n") {
                return String(subtitle[teamIdStart..<endOfLine])
            }
        }
        
        return nil
    }
    
    // Fetch active team challenges for a team
    func fetchActiveChallengesForTeam(_ teamId: String) -> [HuntTask] {
        do {
            // We can't use predicate directly on our custom properties
            // So we fetch all tasks and filter them
            let descriptor = FetchDescriptor<HuntTask>()
            let allTasks = try modelContext.fetch(descriptor)
            
            return allTasks.filter { task in
                guard let subtitle = task.subtitle,
                      subtitle.contains("Team Challenge:"),
                      subtitle.contains("Team ID: \(teamId)") else {
                    return false
                }
                
                return !isExpired(task: task) && !task.isCompleted
            }
        } catch {
            print("Error fetching active team challenges: \(error)")
            return []
        }
    }
} 