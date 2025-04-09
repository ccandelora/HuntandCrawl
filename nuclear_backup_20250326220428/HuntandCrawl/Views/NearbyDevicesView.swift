import SwiftUI
import SwiftData
import CoreBluetooth

struct NearbyDevicesView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var messageManager: BluetoothMessageManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingMessageSheet = false
    @State private var selectedDevice: NearbyDevice?
    @State private var messageText = ""
    @State private var isSearching = false
    @State private var isAdvertising = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Bluetooth Status
                bluetoothStatusView
                
                // Device List
                deviceListView
                
                // Controls
                controlsView
            }
            .padding()
            .navigationTitle("Nearby Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMessageSheet) {
                messageSheet
            }
            .sheet(isPresented: $showSettings) {
                BluetoothSettingsView()
            }
        }
    }
    
    // Bluetooth Status View
    private var bluetoothStatusView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: bluetoothManager.isBluetoothEnabled ? "bolt.horizontal.circle.fill" : "bolt.horizontal.circle")
                    .foregroundColor(bluetoothManager.isBluetoothEnabled ? .green : .gray)
                
                Text(bluetoothStatusText)
                    .font(.subheadline)
                    .foregroundColor(bluetoothManager.isBluetoothEnabled ? .primary : .red)
                
                Spacer()
                
                if bluetoothManager.isBluetoothEnabled {
                    Text("\(bluetoothManager.nearbyDevices.count) nearby")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Divider()
        }
    }
    
    // Device List View
    private var deviceListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if bluetoothManager.nearbyDevices.isEmpty && isSearching {
                    noDevicesView
                } else {
                    ForEach(Array(bluetoothManager.nearbyDevices.values), id: \.peripheral.identifier) { device in
                        deviceRow(device)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // No Devices View
    private var noDevicesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No nearby players found")
                .font(.headline)
            
            Text("Keep searching or move closer to other players")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // Device Row
    private func deviceRow(_ device: NearbyDevice) -> some View {
        Button(action: {
            self.selectedDevice = device
            self.showingMessageSheet = true
        }) {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(device.userName?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.userName ?? "Unknown Player")
                        .font(.system(size: 16, weight: .medium))
                    
                    HStack {
                        Text(device.name ?? "Unknown Device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Signal: \(signalStrengthText(for: device.rssi))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Connection Status
                if device.isConnected {
                    Text("Connected")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                } else {
                    Button(action: {
                        bluetoothManager.connectToPeripheral(device.peripheral)
                    }) {
                        Text("Connect")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // Controls View
    private var controlsView: some View {
        HStack(spacing: 16) {
            Button(action: toggleScanning) {
                VStack {
                    Image(systemName: isSearching ? "antenna.radiowaves.left.and.right.slash" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 20))
                    Text(isSearching ? "Stop" : "Search")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .background(isSearching ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(isSearching ? .orange : .blue)
                .cornerRadius(12)
            }
            
            Button(action: toggleAdvertising) {
                VStack {
                    Image(systemName: isAdvertising ? "wifi.slash" : "wifi")
                        .font(.system(size: 20))
                    Text(isAdvertising ? "Invisible" : "Visible")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .background(isAdvertising ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .foregroundColor(isAdvertising ? .green : .gray)
                .cornerRadius(12)
            }
        }
        .padding(.top, 8)
    }
    
    // Message Sheet
    private var messageSheet: some View {
        NavigationStack {
            VStack {
                if let device = selectedDevice {
                    HStack {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Text(device.userName?.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.userName ?? "Unknown Player")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(device.name ?? "Unknown Device")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if device.isConnected {
                                Text("Connected")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(12)
                            } else {
                                Text("Not Connected")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.gray)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                    
                    // Message input
                    if device.isConnected {
                        VStack {
                            HStack {
                                TextField("Type a message...", text: $messageText)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(12)
                                
                                Button(action: sendMessage) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.blue)
                                }
                                .disabled(messageText.isEmpty)
                            }
                            .padding()
                            
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("Not Connected")
                                .font(.headline)
                            
                            Text("Connect to this device to send messages")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                bluetoothManager.connectToPeripheral(device.peripheral)
                            }) {
                                Text("Connect to \(device.userName ?? "Device")")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Send Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingMessageSheet = false
                    }
                }
            }
        }
    }
    
    // Helper function for signal strength display
    private func signalStrengthText(for rssi: Int) -> String {
        switch rssi {
        case -50...:
            return "Excellent"
        case -70...:
            return "Good"
        case -80...:
            return "Fair"
        default:
            return "Poor"
        }
    }
    
    // Helper property for Bluetooth status text
    private var bluetoothStatusText: String {
        if !bluetoothManager.isBluetoothEnabled {
            return "Bluetooth is turned off"
        }
        
        switch bluetoothManager.authorizationStatus {
        case .allowedAlways:
            return "Bluetooth is enabled"
        case .notDetermined:
            return "Bluetooth permission needed"
        case .restricted, .denied:
            return "Bluetooth permission denied"
        @unknown default:
            return "Bluetooth status unknown"
        }
    }
    
    // Toggle scanning
    private func toggleScanning() {
        isSearching.toggle()
        
        if isSearching {
            bluetoothManager.startScanning()
        } else {
            bluetoothManager.stopScanning()
        }
    }
    
    // Toggle advertising
    private func toggleAdvertising() {
        isAdvertising.toggle()
        
        if isAdvertising {
            bluetoothManager.startAdvertising()
        } else {
            bluetoothManager.stopAdvertising()
        }
    }
    
    // Send a message
    private func sendMessage() {
        guard let device = selectedDevice, !messageText.isEmpty else { return }
        
        // Send the message
        messageManager.sendTextMessage(messageText, to: device)
        
        // Clear the input field
        messageText = ""
    }
}

// Settings View
struct BluetoothSettingsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var userName = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your Profile")) {
                    TextField("Your Name", text: $userName)
                        .autocapitalization(.words)
                }
                
                Section(header: Text("Bluetooth")) {
                    Toggle("Search for Players", isOn: Binding<Bool>(
                        get: { bluetoothManager.isScanning },
                        set: { newValue in
                            if newValue {
                                bluetoothManager.startScanning()
                            } else {
                                bluetoothManager.stopScanning()
                            }
                        }
                    ))
                    
                    Toggle("Be Visible to Others", isOn: Binding<Bool>(
                        get: { bluetoothManager.isAdvertising },
                        set: { newValue in
                            if newValue {
                                bluetoothManager.startAdvertising()
                            } else {
                                bluetoothManager.stopAdvertising()
                            }
                        }
                    ))
                }
                
                Section(header: Text("Privacy")) {
                    Button("Clear All Nearby Device Data") {
                        bluetoothManager.clearAllDevices()
                        alertMessage = "Device data cleared"
                        showAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Bluetooth Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Save name before dismissing
                        if !userName.isEmpty {
                            UserDefaults.standard.set(userName, forKey: "bluetooth_username")
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load saved name
                userName = UserDefaults.standard.string(forKey: "bluetooth_username") ?? ""
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

struct NearbyDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        let modelContainer = try! ModelContainer(for: BluetoothPeerMessage.self)
        let bluetoothManager = BluetoothManager()
        let messageManager = BluetoothMessageManager(
            modelContext: modelContainer.mainContext,
            bluetoothManager: bluetoothManager,
            currentUser: nil
        )
        
        return NearbyDevicesView()
            .environmentObject(bluetoothManager)
            .environmentObject(messageManager)
            .modelContainer(modelContainer)
    }
} 