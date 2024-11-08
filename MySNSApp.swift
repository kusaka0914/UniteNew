//
//  MySNSApp.swift
//  MySNS
//
//  Created by 日下拓海 on 2024/09/05.
//

import SwiftUI
import SwiftData
import Firebase
import FirebaseFirestore

@main
struct MySNSApp: App {
    init() {
        // Firebaseの初期化
        FirebaseApp.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(user: User(username: "", university: "", posts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: []))
            .preferredColorScheme(.dark)
                
        }
    }
}