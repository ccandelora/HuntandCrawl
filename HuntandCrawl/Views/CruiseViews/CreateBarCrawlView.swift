import SwiftUI
import SwiftData

struct CreateBarCrawlView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var theme = ""
    @State private var difficulty = "Moderate"
    @State private var estimatedDuration = ""
    @State private var showConfirmDiscard = false
    
    @Query private var user: [User]
    
    private let difficultyOptions = ["Easy", "Moderate", "Challenging"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bar Crawl Details")) {
                    TextField("Name", text: $name)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...)
                    
                    TextField("Theme (e.g. Cocktails, Beer, etc.)", text: $theme)
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(difficultyOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    TextField("Estimated Duration (e.g. 2-3 hours)", text: $estimatedDuration)
                }
                
                Section {
                    Button("Create Bar Crawl") {
                        saveBarCrawl()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
                    .listRowBackground(Color.blue)
                    .disabled(!isFormValid)
                }
                
                Section {
                    Button("Cancel", role: .destructive) {
                        if !formIsEmpty {
                            showConfirmDiscard = true
                        } else {
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Create Bar Crawl")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Discard Changes?", isPresented: $showConfirmDiscard) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to discard your changes?")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBarCrawl()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !estimatedDuration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var formIsEmpty: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        estimatedDuration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveBarCrawl() {
        let barCrawl = BarCrawl(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            barCrawlDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
            theme: theme.trimmingCharacters(in: .whitespacesAndNewlines),
            difficulty: difficulty,
            estimatedDuration: estimatedDuration.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Set the current user as the creator
        if let currentUser = user.first {
            barCrawl.creator = currentUser
        }
        
        // Initialize empty bar stops array
        barCrawl.barStops = []
        
        modelContext.insert(barCrawl)
        
        // Try to save and dismiss
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving bar crawl: \(error)")
        }
    }
}

#Preview {
    CreateBarCrawlView()
        .modelContainer(for: [
            BarCrawl.self,
            User.self,
            CruiseBarStop.self,
            CruiseBar.self
        ], inMemory: true)
} 