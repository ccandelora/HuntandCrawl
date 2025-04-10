import SwiftUI
import SwiftData

struct CruiseBarDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationManager: NavigationManager
    
    let barStop: CruiseBarStop
    
    @State private var showVisitActionSheet = false
    @State private var hasVisited = false
    @State private var selectedRating: Int = 0
    @State private var visitNote: String = ""
    @State private var visitDate: Date = Date()
    @State private var showDrinksList = false
    @State private var showAddBarCrawlSheet = false
    
    private var bar: CruiseBar? {
        barStop.bar
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Bar header
                barHeaderView
                
                // Bar details
                barDetailsView
                
                // Signature drinks
                signatureDrinksView
                
                // Visit button
                recordVisitButtonView
            }
        }
        .navigationTitle(bar?.name ?? "Bar Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddBarCrawlSheet = true
                    } label: {
                        Label("Add to Bar Crawl", systemImage: "plus.circle")
                    }
                    
                    Button {
                        // Share bar
                        let barName = bar?.name ?? "Unknown Bar"
                        let shipName = barStop.ship?.name ?? "Unknown Ship"
                        let shareText = "Check out \(barName) on \(shipName)!"
                        let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .actionSheet(isPresented: $showVisitActionSheet) {
            ActionSheet(
                title: Text("Record Visit"),
                message: Text("Have you visited \(bar?.name ?? "this bar")?"),
                buttons: [
                    .default(Text("Yes, I've visited")) {
                        hasVisited = true
                        // Here you would record the visit in your data model
                    },
                    .default(Text("No, just browsing")) {
                        hasVisited = false
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showDrinksList) {
            drinkListView
        }
        .sheet(isPresented: $showAddBarCrawlSheet) {
            addToBarCrawlView
        }
    }
    
    // MARK: - Bar Header
    
    private var barHeaderView: some View {
        ZStack(alignment: .bottom) {
            // Bar image or placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorForBarType(bar?.barType ?? "").opacity(0.7),
                            colorForBarType(bar?.barType ?? "").opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .overlay(
                    Image(systemName: iconForBarType(bar?.barType ?? ""))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                        .foregroundColor(.white.opacity(0.3))
                )
            
            // Bar info overlay
            VStack(alignment: .leading, spacing: 6) {
                Text(bar?.name ?? "Unknown Bar")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(bar?.barType ?? "")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                HStack {
                    Text("Located on: \(barStop.ship?.name ?? "Unknown Ship")")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    if let costCategory = bar?.costCategory {
                        Text(costCategory)
                            .font(.caption)
                            .padding(6)
                            .background(
                                costCategory.contains("Premium") ?
                                    Color.purple.opacity(0.2) :
                                    (costCategory.contains("Included") ?
                                        Color.green.opacity(0.2) :
                                        Color.orange.opacity(0.2))
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.4))
        }
    }
    
    // MARK: - Bar Details
    
    private var barDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Location
            infoCard(title: "Location") {
                VStack(alignment: .leading, spacing: 12) {
                    infoRow(icon: "location", title: "On Ship", value: barStop.ship?.name ?? "Unknown")
                    infoRow(icon: "map", title: "Deck Location", value: barStop.locationOnShip)
                    
                    if !barStop.specialNotes.isEmpty {
                        Text("Special Notes")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text(barStop.specialNotes)
                            .foregroundColor(.secondary)
                            .padding(.leading)
                    }
                }
            }
            
            // Bar details
            infoCard(title: "About This Bar") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(bar?.barDescription ?? "No description available.")
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    infoRow(icon: "clock", title: "Hours", value: bar?.hours ?? "Unknown")
                    infoRow(icon: "tag", title: "Dress Code", value: bar?.dressCode ?? "Unknown")
                    infoRow(icon: "sparkles", title: "Atmosphere", value: bar?.atmosphere ?? "Unknown")
                    infoRow(icon: "dollarsign.circle", title: "Cost Category", value: bar?.costCategory ?? "Unknown")
                }
            }
            
            // Amenities and features
            infoCard(title: "Features") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    featureBadge(icon: "music.note", text: "Live Music")
                    featureBadge(icon: "tv", text: "Sports TV")
                    featureBadge(icon: "person.2", text: "Social Setting")
                    featureBadge(icon: "wineglass", text: "Craft Cocktails")
                    featureBadge(icon: "beach.umbrella", text: "Outdoor Seating")
                    featureBadge(icon: "moon.stars", text: "Night Views")
                }
            }
        }
        .padding()
    }
    
    // MARK: - Signature Drinks
    
    private var signatureDrinksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let bar = bar, !bar.signatureDrinks.isEmpty {
                infoCard(title: "Signature Drinks") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(bar.signatureDrinks)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showDrinksList = true
                        } label: {
                            Text("View Full Drinks Menu")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Visit Button
    
    private var recordVisitButtonView: some View {
        VStack(spacing: 16) {
            Button {
                showVisitActionSheet = true
            } label: {
                Text("Record Your Visit")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if hasVisited {
                rateVisitView
            }
        }
        .padding(.bottom, 20)
    }
    
    private var rateVisitView: some View {
        VStack(spacing: 16) {
            Text("How was your experience?")
                .font(.headline)
            
            // Star rating
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: selectedRating >= star ? "star.fill" : "star")
                        .foregroundColor(selectedRating >= star ? .yellow : .gray)
                        .font(.title2)
                        .onTapGesture {
                            selectedRating = star
                        }
                }
            }
            
            // Note input
            TextField("Add a note about your visit...", text: $visitNote)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Date picker
            DatePicker("Visit Date", selection: $visitDate, displayedComponents: .date)
                .padding(.horizontal)
            
            // Save button
            Button {
                // Here you would save the visit data
                dismiss()
            } label: {
                Text("Save Visit")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Drink List Sheet
    
    private var drinkListView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let bar = bar {
                        ForEach(mockDrinkCategories(), id: \.name) { category in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.name)
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(category.drinks, id: \.name) { drink in
                                    drinkRow(drink)
                                }
                                
                                Divider()
                                    .padding(.vertical, 8)
                            }
                        }
                    } else {
                        Text("No drinks information available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("\(bar?.name ?? "Bar") Drinks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showDrinksList = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func drinkRow(_ drink: MockDrink) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(drink.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(drink.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(drink.price)
                .font(.subheadline)
                .foregroundColor(drink.price.contains("Included") ? .green : .secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Add to Bar Crawl Sheet
    
    private var addToBarCrawlView: some View {
        NavigationStack {
            // A form to select or create a bar crawl to add this bar to
            Form {
                Section(header: Text("Select Existing Bar Crawl")) {
                    // This would list existing bar crawls
                    Text("Sample Bar Crawl 1")
                    Text("Sample Bar Crawl 2")
                }
                
                Section(header: Text("Or Create New Bar Crawl")) {
                    // Form to create a new bar crawl
                    TextField("Bar Crawl Name", text: .constant(""))
                    
                    Picker("Difficulty Level", selection: .constant("Moderate")) {
                        Text("Easy").tag("Easy")
                        Text("Moderate").tag("Moderate")
                        Text("Challenging").tag("Challenging")
                    }
                    
                    TextField("Estimated Duration", text: .constant("2-3 hours"))
                    
                    TextField("Description", text: .constant(""))
                        .frame(height: 100)
                }
                
                Section {
                    Button {
                        showAddBarCrawlSheet = false
                    } label: {
                        Text("Add to Bar Crawl")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Add to Bar Crawl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showAddBarCrawlSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Helper Views
    
    private func infoCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    private func featureBadge(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    
    private func iconForBarType(_ type: String) -> String {
        if type.lowercased().contains("cocktail") {
            return "wineglass"
        } else if type.lowercased().contains("beer") {
            return "mug"
        } else if type.lowercased().contains("pool") {
            return "waterbottle"
        } else if type.lowercased().contains("irish") {
            return "music.note"
        } else if type.lowercased().contains("whiskey") {
            return "wineglass.fill"
        } else if type.lowercased().contains("tropical") {
            return "leaf"
        } else if type.lowercased().contains("piano") {
            return "pianokeys"
        } else if type.lowercased().contains("ice") {
            return "snowflake"
        } else {
            return "wineglass"
        }
    }
    
    private func colorForBarType(_ type: String) -> Color {
        if type.lowercased().contains("cocktail") {
            return .purple
        } else if type.lowercased().contains("beer") {
            return .orange
        } else if type.lowercased().contains("pool") {
            return .blue
        } else if type.lowercased().contains("irish") {
            return .green
        } else if type.lowercased().contains("whiskey") {
            return .brown
        } else if type.lowercased().contains("tropical") {
            return .green
        } else if type.lowercased().contains("piano") {
            return .black
        } else if type.lowercased().contains("ice") {
            return .blue
        } else {
            return .indigo
        }
    }
    
    // MARK: - Mock Data
    
    private func mockDrinkCategories() -> [MockDrinkCategory] {
        [
            MockDrinkCategory(
                name: "Signature Cocktails",
                drinks: [
                    MockDrink(
                        name: "Cucumber Sunrise",
                        description: "Vodka, cucumber, mint, lime, and soda water. Refreshing and light.",
                        price: "$12.99"
                    ),
                    MockDrink(
                        name: "Blue Ocean",
                        description: "Blue curaçao, vodka, pineapple juice, and a splash of lime.",
                        price: "$14.99"
                    ),
                    MockDrink(
                        name: "Spiced Rum Punch",
                        description: "A tropical blend with spiced rum, orange, pineapple, and grenadine.",
                        price: "Included in Package"
                    )
                ]
            ),
            MockDrinkCategory(
                name: "Beer Selection",
                drinks: [
                    MockDrink(
                        name: "Domestic Draft",
                        description: "Selection of domestic beers on tap.",
                        price: "$6.99"
                    ),
                    MockDrink(
                        name: "Imported Bottles",
                        description: "Selection of imported bottled beers from around the world.",
                        price: "$8.99"
                    ),
                    MockDrink(
                        name: "Craft Beer Flight",
                        description: "Sample four different craft beers.",
                        price: "$15.99"
                    )
                ]
            ),
            MockDrinkCategory(
                name: "Non-Alcoholic",
                drinks: [
                    MockDrink(
                        name: "Tropical Mocktail",
                        description: "Pineapple, orange, and cranberry juice with a splash of grenadine.",
                        price: "$6.99"
                    ),
                    MockDrink(
                        name: "Virgin Mojito",
                        description: "Fresh mint, lime, sugar, and soda water.",
                        price: "Included in Package"
                    ),
                    MockDrink(
                        name: "Sparkling Water",
                        description: "Choice of flavored sparkling water.",
                        price: "Included in Package"
                    )
                ]
            )
        ]
    }
}

// MARK: - Mock Structs

struct MockDrinkCategory {
    let name: String
    let drinks: [MockDrink]
}

struct MockDrink {
    let name: String
    let description: String
    let price: String
}

#Preview {
    NavigationStack {
        CruiseBarDetailView(barStop: previewCruiseBarStop())
    }
    .modelContainer(for: [
        CruiseLine.self,
        CruiseShip.self,
        CruiseBar.self,
        CruiseBarStop.self
    ], inMemory: true)
    .environmentObject(NavigationManager())
}

func previewCruiseBarStop() -> CruiseBarStop {
    let bar = CruiseBar(
        name: "The Alchemy Bar",
        barDescription: "Cocktail bar with signature mixology and unique flavor combinations.",
        barType: "Cocktail Bar",
        signatureDrinks: "Cucumber Sunrise, Blueberry Mojito, Spiced Rum Punch",
        atmosphere: "Upscale, Sophisticated",
        dressCode: "Smart Casual",
        hours: "Noon - 1:00 AM",
        costCategory: "Premium Package"
    )
    
    let ship = CruiseShip(
        name: "Carnival Celebration",
        shipClass: "Excel",
        yearBuilt: 2022,
        passengerCapacity: 5374,
        numberOfBars: 15,
        tonnage: 183521
    )
    
    let barStop = CruiseBarStop(
        locationOnShip: "Deck 5, Midship",
        specialNotes: "Featured mixology demonstrations daily at 3:00 PM"
    )
    
    barStop.bar = bar
    barStop.ship = ship
    
    return barStop
} 