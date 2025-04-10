//
//  ContentView.swift
//  HuntandCrawl
//
//  Created by Chris Candelora on 3/26/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CruiseLineListView()
                .navigationTitle("Cruise Lines")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CruiseLine.self, CruiseShip.self, CruiseBar.self], inMemory: true)
}
