import SwiftUI
import SwiftData

struct SyncStatusView: View {
    @Binding var syncStatus: SyncManager.SyncStatus
    @Binding var pendingSyncCount: Int

    var body: some View {
        HStack {
            // Sync icon
            syncIcon
                .font(.system(size: 18))
                .id("statusIcon") // Add identifier for testing

            // Sync status text
            Text(statusText)
                .font(.footnote)

            Spacer()

            // Pending count (optional)
            if pendingSyncCount > 0 && !isSyncing {
                Text("\(pendingSyncCount) pending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(8)
        .animation(.easeInOut, value: syncStatus)
        .animation(.easeInOut, value: pendingSyncCount)
    }

    // Helper property to check if syncing
    private var isSyncing: Bool {
        if case .syncing = syncStatus {
            return true
        }
        return false
    }

    // Computed properties for dynamic UI
    private var syncIcon: Image {
        switch syncStatus {
        case .idle:
            return Image(systemName: "arrow.clockwise.circle")
        case .syncing:
            return Image(systemName: "arrow.triangle.2.circlepath.circle") // Use a rotating icon
        case .synced:
            return Image(systemName: "checkmark.circle.fill")
        case .offline:
            return Image(systemName: "wifi.slash")
        case .error:
            return Image(systemName: "xmark.circle.fill")
        }
    }

    private var statusText: String {
        switch syncStatus {
        case .idle:
            return pendingSyncCount > 0 ? "Sync Needed" : "Up to date"
        case .syncing:
            return "Syncing (\(pendingSyncCount))..."
        case .synced:
            return "Sync Complete"
        case .offline:
            return "Offline Mode" + (pendingSyncCount > 0 ? " (\(pendingSyncCount) pending)" : "")
        case .error(let message):
            return "Sync Failed: \(message)"
        }
    }

    private var backgroundColor: Color {
        switch syncStatus {
        case .idle:
            return Color(UIColor.systemGray5)
        case .syncing:
            return Color.blue.opacity(0.2)
        case .synced:
            return Color.green.opacity(0.2)
        case .offline:
            return Color.orange.opacity(0.2)
        case .error:
            return Color.red.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch syncStatus {
        case .idle:
            return Color.secondary
        case .syncing:
            return Color.blue
        case .synced:
            return Color.green
        case .offline:
            return Color.orange
        case .error:
            return Color.red
        }
    }
}

// Preview Provider
struct SyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @State private var status: SyncManager.SyncStatus = .idle
        @State private var count: Int = 5

        var body: some View {
            VStack(spacing: 20) {
                SyncStatusView(syncStatus: $status, pendingSyncCount: $count)
                
                Button("Simulate Syncing") { status = .syncing }
                Button("Simulate Success") { status = .synced; count = 0 }
                Button("Simulate Offline") { status = .offline; count = 3 }
                Button("Simulate Error") { status = .error("Connection failed") }
                Button("Simulate Idle (Pending)") { status = .idle; count = 3 }
                Button("Simulate Idle (Up to Date)") { status = .idle; count = 0 }
            }
            .padding()
        }
    }
} 