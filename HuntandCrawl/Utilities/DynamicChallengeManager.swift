import Foundation
import SwiftData
import Combine
import CoreLocation

class DynamicChallengeManager: ObservableObject {
    private var modelContext: ModelContext
    private var locationManager: LocationManager?
    
    // Published properties
    @Published var pendingChallenges: [Task] = []
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
    func generateTeamChallenge(for hunt: Hunt, teamId: UUID) -> AnyPublisher<Task, Error> {
        return Future<Task, Error> { [weak self] promise in
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
            let challengeTitle = "Team Challenge: " + self.challengeTemplates.randomElement()!
            
            // Create the challenge task
            let task = Task(
                hunt: hunt,
                name: challengeTitle,
                description: "Complete this challenge with your team members!",
                points: Int.random(in: 50...150),
                latitude: 0,
                longitude: 0,
                verificationMethod: .photo,
                order: hunt.tasks.count + 1
            )
            
            // Set dynamic and team-specific properties
            task.isDynamic = true
            task.teamId = teamId
            
            // Set location to current location if available
            if let location = self.locationManager?.userLocation {
                task.latitude = location.coordinate.latitude
                task.longitude = location.coordinate.longitude
            }
            
            // Add expiration time (1 hour from now)
            task.expiresAt = Date().addingTimeInterval(3600)
            task.generatedAt = Date()
            task.minimumTeamMembers = self.minimumTeamMembersRequired
            
            // Add it to the hunt
            hunt.tasks.append(task)
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
    func isEligibleForCompletion(task: Task) -> Bool {
        // Make sure it's a dynamic challenge
        guard task.isDynamic else { return false }
        
        // Make sure it has a team ID
        guard let teamId = task.teamId else { return false }
        
        // Make sure it hasn't expired
        guard !task.isExpired else { return false }
        
        // For now, we don't enforce team member proximity without Bluetooth
        // Just check if the task is within its time window
        return true
    }
    
    // Fetch active team challenges for a team
    func fetchActiveChallengesForTeam(_ teamId: UUID) -> [Task] {
        do {
            let predicate = #Predicate<Task> { task in
                task.isDynamic == true &&
                task.teamId == teamId &&
                (task.expiresAt == nil || task.expiresAt! > Date()) &&
                task.isCompleted == false
            }
            
            let descriptor = FetchDescriptor<Task>(predicate: predicate)
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching active team challenges: \(error)")
            return []
        }
    }
} 