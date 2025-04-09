import Foundation
import SwiftData
import Combine
import CoreBluetooth

class BluetoothMessageManager: ObservableObject {
    @Published var pendingMessages: [BluetoothPeerMessage] = []
    @Published var receivedMessages: [BluetoothPeerMessage] = []
    @Published var unreadMessageCount: Int = 0
    
    private let bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()
    
    // User information
    let userId = UUID()
    let username = "User-\(Int.random(in: 1000...9999))"
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
        
        // Subscribe to Bluetooth message notifications
        setupBluetoothSubscriptions()
        
        // Start periodic cleanup of expired messages
        startMessageCleanupTimer()
    }
    
    // MARK: - Message Sending
    
    func sendTextMessage(content: String, to receiverId: UUID? = nil) {
        let message = BluetoothPeerMessage(
            senderId: userId,
            senderName: username,
            receiverId: receiverId,
            messageType: .text,
            content: content
        )
        
        sendMessage(message)
    }
    
    func sendTaskCompletionMessage(taskId: UUID, to receiverId: UUID? = nil) {
        let message = BluetoothPeerMessage(
            senderId: userId,
            senderName: username,
            receiverId: receiverId,
            messageType: .taskCompletion,
            data: ["taskId": taskId.uuidString]
        )
        
        sendMessage(message)
    }
    
    func sendBarStopVisitMessage(barStopId: UUID, barCrawlId: UUID, to receiverId: UUID? = nil) {
        let message = BluetoothPeerMessage(
            senderId: userId,
            senderName: username,
            receiverId: receiverId,
            messageType: .barStopVisit,
            data: [
                "barStopId": barStopId.uuidString,
                "barCrawlId": barCrawlId.uuidString,
                "visitedAt": Date().timeIntervalSince1970
            ]
        )
        
        sendMessage(message)
    }
    
    func sendTeamLocationMessage(latitude: Double, longitude: Double, to receiverId: UUID? = nil) {
        let message = BluetoothPeerMessage(
            senderId: userId,
            senderName: username,
            receiverId: receiverId,
            messageType: .teamLocation,
            data: [
                "latitude": latitude,
                "longitude": longitude,
                "timestamp": Date().timeIntervalSince1970
            ],
            expiresAt: Date().addingTimeInterval(600) // Expires in 10 minutes
        )
        
        sendMessage(message)
    }
    
    func sendTeamChatMessage(content: String, teamId: UUID, to receiverId: UUID? = nil) {
        let message = BluetoothPeerMessage(
            senderId: userId,
            senderName: username,
            receiverId: receiverId,
            messageType: .teamChat,
            content: content,
            data: ["teamId": teamId.uuidString]
        )
        
        sendMessage(message)
    }
    
    private func sendMessage(_ message: BluetoothPeerMessage) {
        do {
            let messageData = try message.toData()
            
            if let receiverId = message.receiverId, 
               let peripheral = findPeripheralFor(userId: receiverId) {
                // Send to specific device
                bluetoothManager.sendData(messageData, to: peripheral)
            } else {
                // Broadcast to all connected devices
                bluetoothManager.sendDataToAllConnectedDevices(messageData)
            }
            
            // Add to pending messages
            pendingMessages.append(message)
            
        } catch {
            print("Error encoding message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Receiving
    
    func handleReceivedMessageData(_ data: Data) {
        do {
            let message = try BluetoothPeerMessage.fromData(data)
            
            // Skip messages from self
            if message.senderId == userId {
                return
            }
            
            // Skip messages not intended for this device
            if let receiverId = message.receiverId, receiverId != userId {
                return
            }
            
            // Skip expired messages
            if message.isExpired {
                return
            }
            
            // Add to received messages
            DispatchQueue.main.async {
                self.receivedMessages.append(message)
                self.updateUnreadCount()
            }
            
        } catch {
            print("Error decoding message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Management
    
    func deleteMessage(_ message: BluetoothPeerMessage) {
        if let index = receivedMessages.firstIndex(where: { $0.id == message.id }) {
            DispatchQueue.main.async {
                self.receivedMessages.remove(at: index)
                self.updateUnreadCount()
            }
        } else if let index = pendingMessages.firstIndex(where: { $0.id == message.id }) {
            DispatchQueue.main.async {
                self.pendingMessages.remove(at: index)
            }
        }
    }
    
    func markMessageAsRead(_ message: BluetoothPeerMessage) {
        if let index = receivedMessages.firstIndex(where: { $0.id == message.id }) {
            DispatchQueue.main.async {
                self.receivedMessages[index].isRead = true
                self.updateUnreadCount()
            }
        }
    }
    
    func markAllMessagesAsRead() {
        DispatchQueue.main.async {
            for i in 0..<self.receivedMessages.count {
                self.receivedMessages[i].isRead = true
            }
            self.updateUnreadCount()
        }
    }
    
    func clearExpiredMessages() {
        let now = Date()
        
        DispatchQueue.main.async {
            self.receivedMessages.removeAll { message in
                if let expiresAt = message.expiresAt {
                    return now > expiresAt
                }
                return false
            }
            
            self.pendingMessages.removeAll { message in
                if let expiresAt = message.expiresAt {
                    return now > expiresAt
                }
                return false
            }
            
            self.updateUnreadCount()
        }
    }
    
    private func updateUnreadCount() {
        unreadMessageCount = receivedMessages.filter { !$0.isRead }.count
    }
    
    // MARK: - Bluetooth Helpers
    
    private func setupBluetoothSubscriptions() {
        bluetoothManager.$nearbyDevices
            .sink { [weak self] devices in
                // Resend pending messages to new devices if needed
                self?.resendPendingMessagesIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    private func resendPendingMessagesIfNeeded() {
        // Logic to resend messages to newly discovered devices
    }
    
    private func findPeripheralFor(userId: UUID) -> CBPeripheral? {
        for device in bluetoothManager.nearbyDevices {
            if device.userId == userId {
                return device.peripheral
            }
        }
        return nil
    }
    
    private func startMessageCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.clearExpiredMessages()
        }
    }
} 