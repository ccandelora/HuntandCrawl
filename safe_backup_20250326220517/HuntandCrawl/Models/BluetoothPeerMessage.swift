import Foundation
import SwiftData

enum MessageType: String, Codable {
    case text
    case taskCompletion
    case barStopVisit
    case teamLocation
    case teamChat
    case teamUpdate
    case synchRequest
    case synchResponse
}

class BluetoothPeerMessage: Codable {
    var id: UUID
    var senderId: UUID
    var senderName: String
    var receiverId: UUID?
    var messageType: MessageType
    var content: String?
    var timestamp: Date
    var isRead: Bool
    var data: [String: Any]?
    var expiresAt: Date?
    
    init(
        id: UUID = UUID(),
        senderId: UUID,
        senderName: String,
        receiverId: UUID? = nil,
        messageType: MessageType,
        content: String? = nil,
        data: [String: Any]? = nil,
        isRead: Bool = false,
        timestamp: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.receiverId = receiverId
        self.messageType = messageType
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
        self.data = data
        self.expiresAt = expiresAt
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else {
            return false
        }
        return Date() > expiresAt
    }
    
    // Custom Codable implementation to handle the dictionary
    private enum CodingKeys: String, CodingKey {
        case id, senderId, senderName, receiverId, messageType, content, timestamp, isRead, dataJson, expiresAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        senderId = try container.decode(UUID.self, forKey: .senderId)
        senderName = try container.decode(String.self, forKey: .senderName)
        receiverId = try container.decodeIfPresent(UUID.self, forKey: .receiverId)
        messageType = try container.decode(MessageType.self, forKey: .messageType)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        
        // Decode the data dictionary from JSON string
        if let dataJsonString = try container.decodeIfPresent(String.self, forKey: .dataJson),
           let jsonData = dataJsonString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            data = dict
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(senderName, forKey: .senderName)
        try container.encodeIfPresent(receiverId, forKey: .receiverId)
        try container.encode(messageType, forKey: .messageType)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isRead, forKey: .isRead)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        
        // Encode the data dictionary to a JSON string
        if let data = data,
           let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            try container.encode(jsonString, forKey: .dataJson)
        }
    }
    
    // Convert message to Data for Bluetooth transmission
    func toData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(self)
    }
    
    // Create a message from received Data
    static func fromData(_ data: Data) throws -> BluetoothPeerMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(BluetoothPeerMessage.self, from: data)
    }
} 