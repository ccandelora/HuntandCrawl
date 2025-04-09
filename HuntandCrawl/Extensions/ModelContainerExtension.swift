import Foundation
import SwiftData

#if DEBUG
extension ModelContainer {
    static var shared: ModelContainer = {
        do {
            // Include all model classes that need to be shared
            let schema = Schema([
                Team.self,
                User.self,
                Hunt.self,
                Task.self,
                BarCrawl.self,
                BarStop.self,
                TaskCompletion.self,
                BarStopVisit.self,
                SyncEvent.self
            ])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            return container
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }()
}
#endif 