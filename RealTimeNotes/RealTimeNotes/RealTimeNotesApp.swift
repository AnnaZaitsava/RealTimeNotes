//
//  RealTimeNotesApp.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//

import SwiftUI
import Firebase

@main
struct RealTimeNotesApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NotesListView()
        }
    }
}

