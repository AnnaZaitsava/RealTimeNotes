//
//  Note.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//

import Foundation
import FirebaseFirestore

struct Note: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var content: String
    var date: Date
    var userId: String
}

