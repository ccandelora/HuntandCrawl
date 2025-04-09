import SwiftUI

struct SearchFilterView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Filter state
    @State private var selectedItemTypes: Set<ItemType> = [.hunts, .barCrawls]
    @State private var selectedSort: SortOption = .newest
    @State private var maxDistance: Double = 10.0
    @State private var includeCompleted = false
    @State private var dateRange: DateRange = .all
    @State private var minRating: Int = 0
    @State private var selectedCategories: Set<String> = []
    
    // Custom date range
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var showingDatePicker = false
    
    // Enums for filter options
    enum ItemType: String, CaseIterable, Identifiable {
        case hunts = "Scavenger Hunts"
        case barCrawls = "Bar Crawls"
        case tasks = "Tasks"
        
        var id: String { self.rawValue }
        var icon: String {
            switch self {
            case .hunts: return "map.fill"
            case .barCrawls: return "wineglass.fill"
            case .tasks: return "checklist"
            }
        }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case distance = "Closest First"
        case popular = "Most Popular"
        case rated = "Highest Rated"
        
        var id: String { self.rawValue }
    }
    
    enum DateRange: String, CaseIterable, Identifiable {
        case all = "All Time"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case custom = "Custom Range"
        
        var id: String { self.rawValue }
    }
    
    // Sample categories
    let categories = [
        "Adventure", "Food & Drink", "Art & Culture",
        "History", "Nightlife", "Family Friendly",
        "Outdoors", "Sightseeing", "Challenges"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Item types
                Section("What are you looking for?") {
                    ForEach(ItemType.allCases) { itemType in
                        Button {
                            toggleItemType(itemType)
                        } label: {
                            HStack {
                                Image(systemName: itemType.icon)
                                    .foregroundColor(.blue)
                                Text(itemType.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedItemTypes.contains(itemType) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Sort by
                Section("Sort by") {
                    Picker("Sort Order", selection: $selectedSort) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Distance filter
                Section {
                    VStack(alignment: .leading) {
                        Text("Maximum Distance: \(Int(maxDistance)) miles")
                        Slider(value: $maxDistance, in: 1...50, step: 1)
                    }
                } header: {
                    Text("Distance")
                } footer: {
                    Text("Shows items within this distance from your current location")
                }
                
                // Date range
                Section("Date Range") {
                    Picker("Time Period", selection: $dateRange) {
                        ForEach(DateRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if dateRange == .custom {
                        Button {
                            showingDatePicker.toggle()
                        } label: {
                            HStack {
                                Text("Custom Range")
                                Spacer()
                                Text("\(formattedDate(customStartDate)) - \(formattedDate(customEndDate))")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showingDatePicker {
                            DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                            DatePicker("End Date", selection: $customEndDate, in: customStartDate..., displayedComponents: .date)
                        }
                    }
                }
                
                // Categories
                Section("Categories") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            CategoryToggle(
                                category: category,
                                isSelected: selectedCategories.contains(category),
                                action: { toggleCategory(category) }
                            )
                        }
                    }
                }
                
                // Additional filters
                Section("Additional Filters") {
                    Toggle("Include Completed", isOn: $includeCompleted)
                    
                    HStack {
                        Text("Minimum Rating")
                        Spacer()
                        RatingPicker(rating: $minRating)
                    }
                }
                
                // Action buttons
                Section {
                    Button("Apply Filters") {
                        applyFilters()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    
                    Button("Reset to Defaults") {
                        resetFilters()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleItemType(_ type: ItemType) {
        if selectedItemTypes.contains(type) {
            if selectedItemTypes.count > 1 {
                selectedItemTypes.remove(type)
            }
        } else {
            selectedItemTypes.insert(type)
        }
    }
    
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func applyFilters() {
        // In a real app, this would save the filter settings and apply them
        dismiss()
    }
    
    private func resetFilters() {
        selectedItemTypes = [.hunts, .barCrawls]
        selectedSort = .newest
        maxDistance = 10.0
        includeCompleted = false
        dateRange = .all
        minRating = 0
        selectedCategories = []
    }
}

struct CategoryToggle: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue.opacity(0.8) : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RatingPicker: View {
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundColor(i <= rating ? .yellow : .gray)
                    .onTapGesture {
                        rating = i
                    }
            }
        }
    }
}

#Preview {
    SearchFilterView()
} 