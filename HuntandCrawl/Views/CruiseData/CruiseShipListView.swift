import SwiftUI
import SwiftData

struct CruiseShipListView: View {
    var cruiseLine: CruiseLine
    @State private var searchText = ""
    
    var filteredShips: [CruiseShip] {
        if searchText.isEmpty {
            return cruiseLine.ships ?? []
        } else {
            return cruiseLine.ships?.filter { $0.name.localizedCaseInsensitiveContains(searchText) } ?? []
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredShips) { ship in
                shipRow(ship)
            }
        }
        .searchable(text: $searchText, prompt: "Search ships")
        .navigationTitle("\(cruiseLine.name) Ships")
        .overlay {
            if cruiseLine.ships?.isEmpty ?? true {
                ContentUnavailableView(
                    "No Ships",
                    systemImage: "ferry",
                    description: Text("No ships available for this cruise line.")
                )
            }
        }
    }
    
    @ViewBuilder
    private func shipRow(_ ship: CruiseShip) -> some View {
        NavigationLink(destination: CruiseShipDetailView(ship: ship)) {
            HStack {
                Image(systemName: "ferry.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(ship.name)
                        .font(.headline)
                    
                    HStack {
                        Text("\(ship.yearBuilt)")
                        Text("• \(ship.shipClass)")
                        Text("• \(ship.tonnage) GT")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(ship.barStops?.count ?? 0) bars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        CruiseShipListView(cruiseLine: CruiseLine.example)
    }
    .modelContainer(for: [CruiseLine.self, CruiseShip.self], inMemory: true)
} 
