import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    
    enum LeaderboardType: String, CaseIterable, Identifiable {
        case individual = "Individual"
        case team = "Team"
        
        var id: String { self.rawValue }
    }
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case allTime = "All Time"
        case thisMonth = "This Month"
        case thisWeek = "This Week"
        
        var id: String { self.rawValue }
    }
    
    @State private var selectedType: LeaderboardType = .individual
    @State private var selectedTimeFrame: TimeFrame = .allTime
    
    // Sample data structures
    struct LeaderboardEntry: Identifiable {
        let id = UUID()
        let name: String
        let points: Int
        let completedTasks: Int
        let rank: Int
    }
    
    // Sample data
    let individualEntries: [LeaderboardEntry] = [
        LeaderboardEntry(name: "Sarah Johnson", points: 1250, completedTasks: 42, rank: 1),
        LeaderboardEntry(name: "Michael Chen", points: 1100, completedTasks: 38, rank: 2),
        LeaderboardEntry(name: "Emma Williams", points: 950, completedTasks: 35, rank: 3),
        LeaderboardEntry(name: "David Kim", points: 880, completedTasks: 32, rank: 4),
        LeaderboardEntry(name: "Lisa Rodriguez", points: 810, completedTasks: 30, rank: 5),
        LeaderboardEntry(name: "James Taylor", points: 750, completedTasks: 25, rank: 6),
        LeaderboardEntry(name: "Olivia Brown", points: 700, completedTasks: 24, rank: 7),
        LeaderboardEntry(name: "Ethan Davis", points: 650, completedTasks: 22, rank: 8),
        LeaderboardEntry(name: "Sophia Martinez", points: 600, completedTasks: 20, rank: 9),
        LeaderboardEntry(name: "Noah Garcia", points: 550, completedTasks: 18, rank: 10)
    ]
    
    let teamEntries: [LeaderboardEntry] = [
        LeaderboardEntry(name: "Urban Explorers", points: 4500, completedTasks: 150, rank: 1),
        LeaderboardEntry(name: "Adventure Seekers", points: 4200, completedTasks: 140, rank: 2),
        LeaderboardEntry(name: "City Slickers", points: 3800, completedTasks: 130, rank: 3),
        LeaderboardEntry(name: "Night Crawlers", points: 3500, completedTasks: 120, rank: 4),
        LeaderboardEntry(name: "The Regulars", points: 3200, completedTasks: 110, rank: 5),
        LeaderboardEntry(name: "Pub Pioneers", points: 2900, completedTasks: 100, rank: 6),
        LeaderboardEntry(name: "Downtown Devils", points: 2600, completedTasks: 90, rank: 7),
        LeaderboardEntry(name: "Brew Crew", points: 2300, completedTasks: 80, rank: 8),
        LeaderboardEntry(name: "Weekend Warriors", points: 2000, completedTasks: 70, rank: 9),
        LeaderboardEntry(name: "Happy Hour Heroes", points: 1700, completedTasks: 60, rank: 10)
    ]
    
    var currentEntries: [LeaderboardEntry] {
        selectedType == .individual ? individualEntries : teamEntries
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filters
            VStack {
                Picker("Type", selection: $selectedType) {
                    ForEach(LeaderboardType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .bottom])
            }
            .background(Color.white)
            
            // Leaderboard
            List {
                HStack {
                    Text("Rank")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .center)
                    
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .center)
                    
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                
                ForEach(currentEntries) { entry in
                    HStack {
                        // Rank
                        Text("\(entry.rank)")
                            .font(.headline)
                            .foregroundColor(rankColor(for: entry.rank))
                            .frame(width: 50, alignment: .center)
                        
                        // Name
                        Text(entry.name)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Tasks
                        Text("\(entry.completedTasks)")
                            .frame(width: 50, alignment: .center)
                        
                        // Points
                        Text("\(entry.points)")
                            .font(.headline)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .brown
        default:
            return .primary
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
} 