//
//  NotesViewModel.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//

import Foundation
import Firebase
import FirebaseFirestore
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var errorMessage: String? = nil

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    private var isFetching = false

    private var userId: String {
        return UserService.getUserId()
    }

    func loadNotes() {
        guard !isFetching else { return }
        isFetching = true

        var query: Query = db.collection("notes")
            .order(by: "date", descending: true)
            .limit(to: 20)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isFetching = false

            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            if let snapshot = snapshot {
                let loadedNotes = snapshot.documents.compactMap {
                    try? $0.data(as: Note.self)
                }

                let newNotes = loadedNotes.filter { newNote in
                    !self.notes.contains { existingNote in
                        existingNote.id == newNote.id
                    }
                }

                if !newNotes.isEmpty {
                    self.notes.append(contentsOf: newNotes)
                }

                self.lastDocument = snapshot.documents.last
            }
        }
    }

    func listenForUpdates() {
        listener = db.collection("notes")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                if let snapshot = snapshot {
                    self.notes = snapshot.documents.compactMap {
                        try? $0.data(as: Note.self)
                    }
                }
            }
    }

    func deleteNote(_ note: Note) {
        guard let noteId = note.id else { return }
        db.collection("notes").document(noteId).delete { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func addNote(title: String, content: String) {
        let newNote = Note(
            title: title.isEmpty ? "New Note" : title,
            content: content,
            date: Date(),
            userId: userId
        )

        do {
            let _ = try db.collection("notes").addDocument(from: newNote)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopListening() {
        listener?.remove()
    }
}
