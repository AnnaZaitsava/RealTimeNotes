//
//  NotesViewModel.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 23.12.24.

import Firebase
import FirebaseFirestore
import SwiftUI

final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var errorMessage: String? = nil
    @Published var isFetching = false

    private var db = Firestore.firestore()
    private var globalListeners: [String: ListenerRegistration] = [:]
    private var singleListeners: [String: ListenerRegistration] = [:]
    private var lastDocument: DocumentSnapshot?

    private var userId: String {
        return UserService.getUserId()
    }

    // MARK: - Load Notes
    func loadNotes() {
        guard !isFetching else { return }
        isFetching = true
        
        var query: Query = db.collection("notes")
            .order(by: "date", descending: true)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isFetching = false
            
            if let error = error {
                self.handleError(error)
                return
            }
            
            if let snapshot = snapshot {
                let loadedNotes = snapshot.documents.compactMap {
                    try? $0.data(as: Note.self)
                }
                
                DispatchQueue.main.async {
                    let uniqueNotes = loadedNotes.filter { newNote in
                        !self.notes.contains(where: { $0.id == newNote.id })
                    }
                    self.notes.append(contentsOf: uniqueNotes)
                    self.lastDocument = snapshot.documents.last
                }
            }
        }
    }
    

    // MARK: - Listen for Updates
    func listenForUpdates() {
        guard globalListeners["allNotes"] == nil else { return }
        let listener = db.collection("notes")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.handleError(error)
                    return
                }

                if let snapshot = snapshot {
                    DispatchQueue.main.async {
                        self.notes = snapshot.documents.compactMap {
                            try? $0.data(as: Note.self)
                        }
                    }
                }
            }

        globalListeners["allNotes"] = listener
    }

    // MARK: - Add Note
    func addNote(title: String, content: String, completion: @escaping (Bool) -> Void) {
        let newNote = Note(
            title: title.isEmpty ? "New Title" : title,
            content: content,
            date: Date(),
            userId: self.userId
        )

        do {
            let _ = try db.collection("notes").addDocument(from: newNote) { error in
                if let error = error {
                    self.handleError(error)
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } catch {
            self.handleError(error)
            completion(false)
        }
    }
    
    // MARK: - Delete Note
    func deleteNote(_ note: Note) {
        guard let noteId = note.id else { return }
        db.collection("notes").document(noteId).delete { [weak self] error in
            if let error = error {
                self?.handleError(error)
            }
        }
    }

    // MARK: - Note Editing with Locking
    
    func startEditing(note: Binding<Note>, completion: @escaping (Bool, String?) -> Void) {
        guard let noteId = note.wrappedValue.id else {
            completion(false, "Note ID is missing.")
            return
        }

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let noteRef = self.db.collection("notes").document(noteId)

            do {
                let noteSnapshot = try transaction.getDocument(noteRef)

                if let lockedBy = noteSnapshot.data()?["lockedBy"] as? String, !lockedBy.isEmpty, lockedBy != self.userId {
                    errorPointer?.pointee = NSError(domain: "FirestoreError", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "The note is locked by another user."
                    ])
                    return nil
                }

                transaction.updateData(["lockedBy": self.userId], forDocument: noteRef)
            } catch {
                errorPointer?.pointee = NSError(domain: "FirestoreError", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: error.localizedDescription
                ])
                return nil
            }

            return self.userId
        }) { [weak self] result, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else if let newLockedBy = result as? String {
                self?.listenForSingleNoteUpdates(note: note) { updatedNote in
                    note.wrappedValue = updatedNote
                }
                completion(true, newLockedBy)
            } else {
                completion(false, "Unknown error occurred during transaction.")
            }
        }
    }
    
    private func lockNote(noteId: String) {
        db.collection("notes").document(noteId).updateData([
            "lockedBy": userId
        ]) { error in
            if let error = error {
                print("Error locking note: \(error.localizedDescription)")
            }
        }
    }

    func stopEditing(note: Note) {
        guard let noteId = note.id else { return }

        db.collection("notes").document(noteId).updateData([
            "lockedBy": FieldValue.delete()
        ]) { error in
            if let error = error {
                self.handleError(error)
            }
        }
    }
    
    // MARK: - Update Note
    func updateNote(_ note: Note, title: String, content: String, completion: @escaping (Bool) -> Void) {
        guard let noteId = note.id else {
            completion(false)
            return
        }

        var updatedNote = note
        updatedNote.title = title.isEmpty ? "New Title" : title
        updatedNote.content = content
        updatedNote.date = Date()

        do {
            try db.collection("notes").document(noteId).setData(from: updatedNote) { error in
                if let error = error {
                    self.handleError(error)
                    completion(false)
                } else {
                    DispatchQueue.main.async {
                        if let index = self.notes.firstIndex(where: { $0.id == noteId }) {
                            self.notes[index] = updatedNote
                        }
                        completion(true)
                    }
                }
            }
        } catch {
            self.handleError(error)
            completion(false)
        }
    }


    // MARK: - Single Note Updates
    func listenForSingleNoteUpdates(note: Binding<Note>, onUpdate: @escaping (Note) -> Void) {
        guard let noteId = note.wrappedValue.id else { return }

        singleListeners[noteId]?.remove()

        singleListeners[noteId] = db.collection("notes").document(noteId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }

                if let document = documentSnapshot, document.exists {
                    DispatchQueue.main.async {
                        if let updatedNote = try? document.data(as: Note.self) {
                            note.wrappedValue = updatedNote
                            onUpdate(updatedNote)
                        }
                    }
                }
            }
    }

    // MARK: - Stop Listening
    func stopListening(noteId: String? = nil) {
        if let noteId = noteId {
            singleListeners[noteId]?.remove()
            singleListeners[noteId] = nil
        } else {
            globalListeners.values.forEach { $0.remove() }
            globalListeners.removeAll()
        }
    }

    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}
