import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var hunts: [Hunt]
    @Query private var barCrawls: [BarCrawl]
    
    @State private var selectedDate = Date()
    @State private var selectedFilter: EventFilter = .all
    
    enum EventFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case hunts = "Hunts"
        case barCrawls = "Bar Crawls"
        
        var id: String { self.rawValue }
    }
    
    var filteredEvents: [CalendarEvent] {
        var events: [CalendarEvent] = []
        
        // Add hunts if filter allows
        if selectedFilter == .all || selectedFilter == .hunts {
            for hunt in hunts {
                if let start = hunt.startTime, let end = hunt.endTime,
                   isDateInRange(selectedDate, start: start, end: end) {
                    events.append(CalendarEvent(
                        id: hunt.id,
                        title: hunt.name,
                        description: hunt.huntDescription,
                        startTime: start,
                        endTime: end,
                        type: .hunt
                    ))
                }
            }
        }
        
        // Add bar crawls if filter allows
        if selectedFilter == .all || selectedFilter == .barCrawls {
            for barCrawl in barCrawls {
                if let start = barCrawl.startTime, let end = barCrawl.endTime,
                   isDateInRange(selectedDate, start: start, end: end) {
                    events.append(CalendarEvent(
                        id: barCrawl.id,
                        title: barCrawl.name,
                        description: barCrawl.barCrawlDescription,
                        startTime: start,
                        endTime: end,
                        type: .barCrawl
                    ))
                }
            }
        }
        
        // Sort events by start time
        return events.sorted { $0.startTime < $1.startTime }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar header
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .background(Color.white)
            
            // Filter
            Picker("Show", selection: $selectedFilter) {
                ForEach(EventFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .bottom])
            
            // Events for selected date
            List {
                if filteredEvents.isEmpty {
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("There are no events scheduled for this date.")
                    )
                } else {
                    ForEach(filteredEvents, id: \.id) { event in
                        EventRow(event: event)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func isDateInRange(_ date: Date, start: Date, end: Date) -> Bool {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: date)
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        
        return (selectedDay >= startDay && selectedDay <= endDay)
    }
    
    // Model to represent calendar events
    struct CalendarEvent {
        let id: String
        let title: String
        let description: String?
        let startTime: Date
        let endTime: Date
        let type: EventType
        
        enum EventType {
            case hunt, barCrawl
        }
    }
}

struct EventRow: View {
    let event: CalendarView.CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Event indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(eventColor)
                .frame(width: 4, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(timeSpan)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let description = event.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(eventType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(eventColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var eventColor: Color {
        switch event.type {
        case .hunt:
            return .blue
        case .barCrawl:
            return .purple
        }
    }
    
    private var eventType: String {
        switch event.type {
        case .hunt:
            return "Hunt"
        case .barCrawl:
            return "Bar Crawl"
        }
    }
    
    private var timeSpan: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: event.startTime)) - \(formatter.string(from: event.endTime))"
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .modelContainer(PreviewContainer.previewContainer)
            .environmentObject(NavigationManager())
    }
} 