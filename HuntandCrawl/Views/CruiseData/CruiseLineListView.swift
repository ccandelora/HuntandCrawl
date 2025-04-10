import SwiftUI
import SwiftData

struct CruiseLineListView: View {
    @Query private var cruiseLines: [CruiseLine]
    @State private var searchText = ""
    
    var filteredCruiseLines: [CruiseLine] {
        if searchText.isEmpty {
            return cruiseLines
        } else {
            return cruiseLines.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        contentView
            .searchable(text: $searchText, prompt: "Search cruise lines")
            .navigationTitle("Cruise Lines")
    }
    
    // Break down the complex view into smaller parts
    private var contentView: some View {
        ZStack {
            cruiseLinesList
            
            if cruiseLines.isEmpty {
                ContentUnavailableView(
                    "No Cruise Lines",
                    systemImage: "sailboat",
                    description: Text("Cruise line data isn't loaded yet.")
                )
            }
        }
    }
    
    private var cruiseLinesList: some View {
        List {
            ForEach(filteredCruiseLines) { cruiseLine in
                cruiseLineRow(cruiseLine)
            }
        }
    }
    
    private func cruiseLineRow(_ cruiseLine: CruiseLine) -> some View {
        NavigationLink(destination: CruiseShipListView(cruiseLine: cruiseLine)) {
            HStack {
                cruiseLineIcon
                
                cruiseLineInfo(cruiseLine)
                
                Spacer()
                
                Text("\(cruiseLine.ships?.count ?? 0) ships")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var cruiseLineIcon: some View {
        Image(systemName: "sailboat.fill")
            .foregroundColor(.blue)
            .font(.title2)
            .frame(width: 40, height: 40)
            .background(Color.blue.opacity(0.1))
            .clipShape(Circle())
    }
    
    private func cruiseLineInfo(_ cruiseLine: CruiseLine) -> some View {
        VStack(alignment: .leading) {
            Text(cruiseLine.name)
                .font(.headline)
            
            Text(cruiseLine.website)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        CruiseLineListView()
    }
    .modelContainer(for: [CruiseLine.self], inMemory: true)
} 