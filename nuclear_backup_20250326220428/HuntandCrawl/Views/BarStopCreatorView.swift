import SwiftUI
import PhotosUI

struct BarStopCreatorView: View {
    var onSave: (BarStop) -> Void
    var nextOrder: Int
    
    @State private var name = ""
    @State private var description = ""
    @State private var location = ""
    @State private var deckNumber: String = ""
    @State private var specialDrink: String = ""
    @State private var activity: String = ""
    @State private var imageRequired = true
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var image: Data?
    @Environment(\.dismiss) private var dismiss
    
    var isFormValid: Bool {
        !name.isEmpty && !location.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Stop Details")) {
                    HStack {
                        Text("Stop #\(nextOrder)")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                    
                    TextField("Bar Name", text: $name)
                    
                    TextField("Description", text: $description)
                    
                    TextField("Location", text: $location)
                    
                    TextField("Deck Number (Optional)", text: $deckNumber)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Special Features")) {
                    TextField("Special Drink (Optional)", text: $specialDrink)
                    
                    TextField("Activity (Optional)", text: $activity)
                }
                
                Section(header: Text("Photo")) {
                    Toggle("Require Photo at Stop", isOn: $imageRequired)
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let image = image, let uiImage = UIImage(data: image) {
                            HStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Text("Change Bar Image")
                            }
                        } else {
                            Label("Add Bar Image (Optional)", systemImage: "photo")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                image = data
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Bar Stop")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveBarStop()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private func saveBarStop() {
        let barStop = BarStop(name: name, description: description, location: location, order: nextOrder, imageRequired: imageRequired)
        
        if let deckNum = Int(deckNumber) {
            barStop.deckNumber = deckNum
        }
        
        barStop.specialDrink = specialDrink.isEmpty ? nil : specialDrink
        barStop.activity = activity.isEmpty ? nil : activity
        barStop.image = image
        
        onSave(barStop)
        dismiss()
    }
}

#Preview {
    BarStopCreatorView(onSave: { _ in }, nextOrder: 1)
} 