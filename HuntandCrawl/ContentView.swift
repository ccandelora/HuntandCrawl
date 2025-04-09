//
//  ContentView.swift
//  HuntandCrawl
//
//  Created by Chris Candelora on 3/26/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationSplitView {
            ZStack {
                // Main content
                List {
                    if isLoading {
                        ProgressView("Loading items...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if items.isEmpty {
                        Text("No items yet")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(items) { item in
                            NavigationLink {
                                Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                            } label: {
                                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                
                // Error overlay
                if let errorMessage = errorMessage {
                    VStack {
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            loadData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.9)))
                    .shadow(radius: 5)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                loadData()
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        // Simulate a data loading operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            
            // If we still have no items, add a sample one
            if items.isEmpty {
                addItem()
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
            
            do {
                try modelContext.save()
                print("Item added successfully")
            } catch {
                errorMessage = "Failed to save item: \(error.localizedDescription)"
                print("Failed to save item: \(error)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
            
            do {
                try modelContext.save()
                print("Items deleted successfully")
            } catch {
                errorMessage = "Failed to delete items: \(error.localizedDescription)"
                print("Failed to delete items: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
