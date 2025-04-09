import SwiftUI
import SwiftData
import CoreLocation

struct DynamicChallengeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(LocationManager.self) private var locationManager
    
    @State private var dynamicChallengeManager: DynamicChallengeManager?
    
    // Query active hunts
    @Query private var activeHunts: [Hunt]
    
    // State variables
    @State private var selectedHunt: Hunt?
    @State private var selectedTeam: Team?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var generatedChallenge: Task?
    
    // Filter for active hunts
    init() {
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = #Predicate<Hunt> { hunt in
            hunt.startDateTime != nil &&
            hunt.endDateTime != nil &&
            hunt.startDateTime! <= Date() &&
            hunt.endDateTime! >= Date()
        }
        
        _activeHunts = Query(filter: predicate, sort: [SortDescriptor(\Hunt.startDateTime, order: .forward)])
    }
    
    var body: some View {
        VStack {
            headerView
            
            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else {
                contentView
            }
        }
        .padding()
        .navigationTitle("Team Challenges")
        .onAppear {
            setupDynamicChallengeManager()
        }
        .alert("Challenge Created!", isPresented: $showSuccessAlert) {
            Button("View Challenge", role: .cancel) {
                if let challenge = generatedChallenge {
                    navigationManager.navigateToTaskDetail(task: challenge)
                }
            }
            Button("OK", role: .none) {}
        } message: {
            Text("A new team challenge has been created. Complete it before it expires!")
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dynamic Team Challenges")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create fun challenges for your team to complete together! Team challenges expire after one hour.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Divider()
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hunt selection
                huntSelectionSection
                
                // Team selection
                if selectedHunt != nil {
                    teamSelectionSection
                }
                
                // Location status
                if selectedTeam != nil {
                    locationStatusSection
                }
                
                // Generate challenge button
                if selectedHunt != nil && selectedTeam != nil {
                    generateChallengeButton
                }
                
                // Active team challenges
                activeTeamChallengesSection
            }
            .padding(.bottom, 30)
        }
    }
    
    private var huntSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Hunt")
                .font(.headline)
            
            if activeHunts.isEmpty {
                Text("No active hunts available")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(activeHunts) { hunt in
                    Button(action: {
                        selectedHunt = hunt
                        selectedTeam = nil // Reset team when hunt changes
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(hunt.name)
                                    .fontWeight(.medium)
                                
                                if let startTime = hunt.startDateTime, let endTime = hunt.endDateTime {
                                    Text("\(startTime.formatted(date: .abbreviated, time: .shortened)) - \(endTime.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedHunt?.id == hunt.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(selectedHunt?.id == hunt.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Team")
                .font(.headline)
            
            // This would be populated with teams the user is part of for the selected hunt
            // For now, we'll use mock data
            // TODO: Replace with actual team query based on selected hunt
            
            let teams = getTeamsForHunt()
            
            if teams.isEmpty {
                Text("No teams available for this hunt")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(teams) { team in
                    Button(action: {
                        selectedTeam = team
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(team.name)
                                    .fontWeight(.medium)
                                
                                Text("\(team.members.count) members")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedTeam?.id == team.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(selectedTeam?.id == team.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var locationStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location Status")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 2) {
                if locationManager.isAuthorized && locationManager.userLocation != nil {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                        Text("Location available")
                            .fontWeight(.medium)
                    }
                    
                    Text("Your location will be used for the challenge")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    HStack {
                        Image(systemName: "location.slash.fill")
                            .foregroundColor(.red)
                        Text("Location unavailable")
                            .fontWeight(.medium)
                    }
                    
                    Text("Please enable location services to continue")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var generateChallengeButton: some View {
        Button(action: generateChallenge) {
            HStack {
                Image(systemName: "bolt.fill")
                Text("Generate Team Challenge")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(locationManager.isAuthorized && locationManager.userLocation != nil ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(.headline)
        }
        .disabled(!(locationManager.isAuthorized && locationManager.userLocation != nil))
        .padding(.top, 10)
    }
    
    private var activeTeamChallengesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Team Challenges")
                .font(.headline)
            
            let activeTeamChallenges = getActiveTeamChallenges()
            
            if activeTeamChallenges.isEmpty {
                Text("No active team challenges")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(activeTeamChallenges) { challenge in
                    Button(action: {
                        navigationManager.navigateToTaskDetail(task: challenge)
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(challenge.title)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(challenge.points) pts")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Text(challenge.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            if let expiresAt = challenge.expiresAt {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.caption)
                                    Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    if let requirement = challenge.teamRequirementDescription {
                                        Text(requirement)
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.top, 20)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .padding()
            Text("Generating team challenge...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
                .padding()
            
            Text(message)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                self.errorMessage = nil
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .padding()
    }
    
    // MARK: - Logic
    
    private func setupDynamicChallengeManager() {
        if dynamicChallengeManager == nil {
            dynamicChallengeManager = DynamicChallengeManager(
                modelContext: modelContext,
                locationManager: locationManager
            )
        }
    }
    
    private func getTeamsForHunt() -> [Team] {
        if let hunt = selectedHunt {
            // In a real app, we'd filter teams by the selected hunt
            // For now, just get all teams
            do {
                let descriptor = FetchDescriptor<Team>()
                return try modelContext.fetch(descriptor)
            } catch {
                print("Error fetching teams: \(error)")
                return []
            }
        }
        return []
    }
    
    private func getActiveTeamChallenges() -> [Task] {
        guard let selectedTeam = selectedTeam,
              let dynamicChallengeManager = dynamicChallengeManager else {
            return []
        }
        
        return dynamicChallengeManager.fetchActiveChallengesForTeam(selectedTeam.id)
    }
    
    private func generateChallenge() {
        guard let hunt = selectedHunt, 
              let team = selectedTeam,
              let dynamicChallengeManager = dynamicChallengeManager else {
            errorMessage = "Missing hunt, team, or challenge manager"
            return
        }
        
        // Check if location is available
        guard locationManager.isAuthorized && locationManager.userLocation != nil else {
            errorMessage = "Location services are required to create a team challenge."
            return
        }
        
        isLoading = true
        
        dynamicChallengeManager.generateTeamChallenge(for: hunt, teamId: team.id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                
                switch completion {
                case .finished:
                    // Success handled in receiveValue
                    break
                case .failure(let error):
                    errorMessage = "Failed to generate challenge: \(error.localizedDescription)"
                }
            }, receiveValue: { challenge in
                self.generatedChallenge = challenge
                self.showSuccessAlert = true
            })
            .store(in: &dynamicChallengeManager.cancellables)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var modelContext = ModelContext(PreviewContainer.previewContainer)
        
        var body: some View {
            DynamicChallengeView()
                .environmentObject(NavigationManager())
                .environment(LocationManager())
                .modelContext(modelContext)
        }
    }
    
    return PreviewWrapper()
} 