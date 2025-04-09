import SwiftUI

struct SyncStatusView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @ObservedObject var syncManager: SyncManager
    
    var body: some View {
        HStack(spacing: 8) {
            if networkMonitor.isConnected {
                if syncManager.isSyncing {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(syncManager.isSyncing ? 360 : 0))
                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: syncManager.isSyncing)
                    
                    Text("Syncing...")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else if syncManager.pendingSyncCount > 0 {
                    Image(systemName: "exclamationmark.icloud")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("\(syncManager.pendingSyncCount) pending")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .onTapGesture {
                            syncManager.forceSync()
                        }
                } else {
                    Image(systemName: "checkmark.icloud")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if let lastSync = syncManager.lastSyncDate {
                        Text("Synced \(timeAgoString(from: lastSync))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("All synced")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                    .foregroundColor(.red)
                
                Text("Offline")
                    .font(.caption)
                    .foregroundColor(.red)
                
                if syncManager.pendingSyncCount > 0 {
                    Text("(\(syncManager.pendingSyncCount) pending)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 1)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    SyncStatusView(syncManager: SyncManager(
        modelContext: try! ModelContainer(for: [SyncEvent.self, TaskCompletion.self]).mainContext,
        networkMonitor: NetworkMonitor()
    ))
    .environmentObject(NetworkMonitor())
} 