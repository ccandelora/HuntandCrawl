import SwiftUI

struct TaskCreatorView: View {
    var onSave: (Task) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var points = "10"
    @State private var type: TaskType = .photo
    @State private var imageRequired = true
    @State private var hint = ""
    @State private var locationHint = ""
    @Environment(\.dismiss) private var dismiss
    
    var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && Int(points) != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description)
                    
                    Picker("Type", selection: $type) {
                        Text("Photo").tag(TaskType.photo)
                        Text("Location").tag(TaskType.location)
                        Text("Item").tag(TaskType.item)
                        Text("Question").tag(TaskType.question)
                        Text("Activity").tag(TaskType.activity)
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Points", text: $points)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Options")) {
                    if type == .photo || type == .location || type == .item {
                        Toggle("Require Photo Evidence", isOn: $imageRequired)
                    }
                    
                    TextField("Hint (Optional)", text: $hint)
                    
                    if type == .location {
                        TextField("Location Hint (Optional)", text: $locationHint)
                    }
                }
            }
            .navigationTitle("Create Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveTask()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private func saveTask() {
        guard let pointsValue = Int(points) else { return }
        
        let task = Task(
            title: title,
            description: description,
            points: pointsValue,
            type: type,
            order: 0,
            imageRequired: imageRequired
        )
        
        task.hint = hint.isEmpty ? nil : hint
        task.locationHint = locationHint.isEmpty ? nil : locationHint
        
        onSave(task)
        dismiss()
    }
}

#Preview {
    TaskCreatorView(onSave: { _ in })
} 