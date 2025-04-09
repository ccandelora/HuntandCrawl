import Foundation
import SwiftData

#if DEBUG
extension ModelContainer {
    static var shared: ModelContainer = {
        do {
            // Include all model classes that need to be shared
            let container = try ModelContainer(for: 
                BluetoothPeerMessage.self, 
                Team.self, 
                User.self,
                Hunt.self,
                Task.self,
                BarCrawl.self,
                BarStop.self,
                TaskCompletion.self,
                BarStopVisit.self,
                SyncEvent.self
            )
            return container
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }()
}
#endif 