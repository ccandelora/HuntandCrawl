import SwiftUI
import SwiftData

struct CruiseShipsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    
    @Query private var cruiseLines: [CruiseLine]
    @State private var isImporting = false
    @State private var importComplete = false
    @State private var showImportError = false
    @State private var importError: Error?
    @State private var searchText = ""
    
    var filteredCruiseLines: [CruiseLine] {
        if searchText.isEmpty {
            return cruiseLines
        } else {
            return cruiseLines.filter { cruiseLine in
                cruiseLine.name.localizedCaseInsensitiveContains(searchText) ||
                cruiseLine.lineDescription.localizedCaseInsensitiveContains(searchText) ||
                (cruiseLine.ships?.contains(where: { ship in
                    ship.name.localizedCaseInsensitiveContains(searchText) ||
                    ship.shipClass.localizedCaseInsensitiveContains(searchText)
                }) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                        .padding(.top)
                    
                    // Import button
                    if cruiseLines.isEmpty && !isImporting && !importComplete {
                        importDataButton
                    }
                    
                    // Loading indicator
                    if isImporting {
                        ProgressView("Importing cruise data...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                    // Cruise lines and ships
                    if !cruiseLines.isEmpty {
                        cruiseLinesGrid
                    }
                }
                .padding()
            }
            .navigationTitle("Cruise Ships")
            .alert("Import Error", isPresented: $showImportError) {
                Button("OK") {
                    showImportError = false
                }
            } message: {
                Text("Failed to import cruise data: \(importError?.localizedDescription ?? "Unknown error")")
            }
            .searchable(text: $searchText, prompt: "Search cruise lines and ships")
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Discover Cruise Ship Bars")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Explore bars, signature drinks, and bar crawl routes on your favorite cruise ships")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var importDataButton: some View {
        Button {
            importCruiseData()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Import Cruise Data")
            }
            .padding()
            .background(AppColors.defaultPrimary)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(.vertical)
    }
    
    private var cruiseLinesGrid: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            ForEach(filteredCruiseLines) { cruiseLine in
                cruiseLineSection(cruiseLine)
            }
        }
    }
    
    private func cruiseLineSection(_ cruiseLine: CruiseLine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(cruiseLine.name)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text(cruiseLine.lineDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(cruiseLine.ships ?? []) { ship in
                        NavigationLink(destination: CruiseShipDetailView(ship: ship)) {
                            cruiseShipCard(ship)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func cruiseShipCard(_ ship: CruiseShip) -> some View {
        VStack(alignment: .leading) {
            // Ship image or placeholder
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .aspectRatio(1.5, contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "ferry")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60)
                            .foregroundColor(.white.opacity(0.5))
                            .offset(y: -20)
                    )
                
                VStack(alignment: .leading) {
                    Text(ship.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(ship.shipClass)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("\(ship.yearBuilt)", systemImage: "calendar")
                    Spacer()
                    Label("\(ship.numberOfBars) Bars", systemImage: "wineglass")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Label("\(ship.passengerCapacity)", systemImage: "person.2")
                    Spacer()
                    
                    if let barCrawlRoutes = ship.barCrawlRoutes, !barCrawlRoutes.isEmpty {
                        Label("\(barCrawlRoutes.count) Routes", systemImage: "map")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding([.horizontal, .bottom])
        }
        .frame(width: 240)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func importCruiseData() {
        isImporting = true
        
        // Use a basic Task closure without parameters
        Task {
            do {
                try await CruiseDataImportService.shared.importAllCruiseData(modelContext: modelContext)
                
                await MainActor.run {
                    isImporting = false
                    importComplete = true
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    importError = error
                    showImportError = true
                }
            }
        }
    }
}

#Preview {
    CruiseShipsView()
        .modelContainer(for: [
            CruiseLine.self,
            CruiseShip.self,
            CruiseBar.self,
            CruiseBarStop.self,
            CruiseBarDrink.self,
            CruiseBarCrawlRoute.self,
            CruiseBarCrawlStop.self
        ], inMemory: true)
        .environmentObject(NavigationManager())
} 