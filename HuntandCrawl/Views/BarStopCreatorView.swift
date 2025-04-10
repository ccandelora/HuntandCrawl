import SwiftUI
import PhotosUI
import SwiftData

struct BarStopCreatorView: View {
    @Bindable var barCrawl: BarCrawl
    
    @State private var name = ""
    @State private var description = ""
    @State private var location = ""
    @State private var specialDrink = "House Special"
    @State private var drinkPrice = 10.0
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var checkInRadius = 50.0
    @State private var order = 1
    @State private var isVIP = false
    @State private var openingTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var closingTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var image: Data?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var isFormValid: Bool {
        !name.isEmpty && !specialDrink.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Stop Details")) {
                    HStack {
                        Text("Stop #\(order)")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                    
                    TextField("Bar Name", text: $name)
                    
                    TextField("Description", text: $description)
                    
                    TextField("Location", text: $location)
                    
                    TextField("Special Drink", text: $specialDrink)
                    
                    HStack {
                        Text("Drink Price")
                        Spacer()
                        TextField("", value: $drinkPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Location & Check-in")) {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        TextField("Optional", value: $latitude, format: .number.precision(.fractionLength(6)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Longitude")
                        Spacer()
                        TextField("Optional", value: $longitude, format: .number.precision(.fractionLength(6)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Check-in Radius (meters)")
                        Spacer()
                        TextField("", value: $checkInRadius, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Toggle("VIP Location", isOn: $isVIP)
                }
                
                Section(header: Text("Opening Hours")) {
                    DatePicker("Opening Time", selection: $openingTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("Closing Time", selection: $closingTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Add Bar Stop")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBarStop()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveBarStop() {
        // Find the next order number if not specified
        if order <= 0 {
            if let barStops = barCrawl.barStops, !barStops.isEmpty {
                order = (barStops.map { $0.order }.max() ?? 0) + 1
            } else {
                order = 1
            }
        }
        
        let barStop = BarStop(
            name: name,
            specialDrink: specialDrink,
            drinkPrice: drinkPrice,
            barStopDescription: description.isEmpty ? nil : description,
            checkInRadius: checkInRadius,
            deckNumber: Int.random(in: 7...15),
            locationOnShip: location.isEmpty ? "Unspecified" : location,
            section: "Midship",
            openingTime: openingTime,
            closingTime: closingTime,
            order: order,
            isVIP: isVIP
        )
        
        barStop.barCrawl = barCrawl
        modelContext.insert(barStop)
        
        dismiss()
    }
}

// MARK: - Preview
struct BarStopCreatorView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: BarCrawl.self, BarStop.self, configurations: config)
        
        let barCrawl = BarCrawl(name: "Test Crawl", barCrawlDescription: "A fun crawl", startTime: Date(), endTime: Date().addingTimeInterval(3600*3))
        container.mainContext.insert(barCrawl)
        
        return BarStopCreatorView(barCrawl: barCrawl)
            .modelContainer(container)
    }
} 