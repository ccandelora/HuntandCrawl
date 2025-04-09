import Foundation
import SwiftData
import Combine

class SyncManager: ObservableObject {
    private var modelContext: ModelContext
    private var networkMonitor: NetworkMonitor
    var apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties
    @Published var isSyncing: Bool = false
    @Published var pendingSyncCount: Int = 0
    @Published var lastSyncDate: Date?
    
    init(modelContext: ModelContext, networkMonitor: NetworkMonitor) {
        self.modelContext = modelContext
        self.networkMonitor = networkMonitor
        self.apiService = APIService()
        
        // Setup notification observers for connectivity changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectivityChanged),
            name: .connectivityStatusChanged,
            object: nil
        )
        
        // Get initial pending sync count
        updatePendingSyncCount()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func createSyncEvent(type: String, entityId: UUID, data: [String: Any]) {
        // Create a new sync event
        let syncEvent = SyncEvent(
            eventType: type,
            entityId: entityId,
            data: convertToData(data),
            createdAt: Date()
        )
        
        // Save to model context
        modelContext.insert(syncEvent)
        do {
            try modelContext.save()
            updatePendingSyncCount()
        } catch {
            print("Error saving sync event: \(error)")
        }
    }
    
    func startSync() {
        guard !isSyncing && networkMonitor.isConnected else { return }
        
        // Trigger sync of pending events
        syncPendingEvents()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.isSyncing = false
                    self?.lastSyncDate = Date()
                case .failure(let error):
                    self?.isSyncing = false
                    print("Sync failed: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    @objc private func connectivityChanged() {
        if networkMonitor.isConnected && pendingSyncCount > 0 {
            startSync()
        }
    }
    
    private func updatePendingSyncCount() {
        // Get count of pending sync events
        let descriptor = FetchDescriptor<SyncEvent>()
        do {
            let events = try modelContext.fetch(descriptor)
            pendingSyncCount = events.count
        } catch {
            print("Error fetching sync events: \(error)")
            pendingSyncCount = 0
        }
    }
    
    private func convertToData(_ dictionary: [String: Any]) -> Data? {
        do {
            // Convert dictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
            return jsonData
        } catch {
            print("Error converting to data: \(error)")
            return nil
        }
    }
    
    // MARK: - Sync Logic
    
    func syncPendingEvents() -> AnyPublisher<Bool, Error> {
        isSyncing = true
        
        // Fetch all pending sync events
        let descriptor = FetchDescriptor<SyncEvent>()
        
        do {
            let events = try modelContext.fetch(descriptor)
            
            if events.isEmpty {
                isSyncing = false
                return Just(true)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            
            // Create a chain of publishers to sync each event
            let publishers = events.map { syncEvent in
                return syncEvent(syncEvent)
            }
            
            // Combine all publishers and return a single publisher
            return Publishers.MergeMany(publishers)
                .collect()
                .map { results in
                    // Check if all events were synced successfully
                    let allSuccess = results.allSatisfy { $0 }
                    return allSuccess
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    private func syncEvent(_ event: SyncEvent) -> AnyPublisher<Bool, Error> {
        return apiService.syncEvent(event)
            .flatMap { success -> AnyPublisher<Bool, Error> in
                if success {
                    // Delete the event from local storage after successful sync
                    self.modelContext.delete(event)
                    do {
                        try self.modelContext.save()
                        self.updatePendingSyncCount()
                        return Just(true)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    } catch {
                        return Fail(error: error)
                            .eraseToAnyPublisher()
                    }
                } else {
                    return Just(false)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - API Service

class APIService {
    func syncEvent(_ event: SyncEvent) -> AnyPublisher<Bool, Error> {
        // In a real app, this would make an API call to sync the event
        // For now, we'll simulate a successful sync after a short delay
        return Future<Bool, Error> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                // Simulate 90% success rate
                let success = Double.random(in: 0...1) < 0.9
                if success {
                    promise(.success(true))
                } else {
                    promise(.failure(NSError(domain: "APIService", code: 500, userInfo: nil)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
} 