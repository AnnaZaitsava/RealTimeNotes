//
//  EditNote.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//

import SwiftUI

struct EditNotesView: View {
    @Binding var originalNote: Note
    @State private var localNote: Note
    @State private var isLocked: Bool = false
    @Environment(\.dismiss) var dismiss

    var viewModel: NotesViewModel

    init(note: Binding<Note>, viewModel: NotesViewModel) {
        self._originalNote = note
        self._localNote = State(initialValue: note.wrappedValue)
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: { dismiss() }) {
                    Image("backIcon")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding(.leading, 16)
                }
                Text("Edit Note")
                    .font(.system(size: 30, weight: .black, design: .default))
                    .foregroundColor(.black)
                    .padding(.leading, 10)

                if isLocked {
                    Spacer()
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                    }
                }
            }
            .padding(.top, 20)

            TextField("Add title here", text: $localNote.title)
                .disabled(isLocked)
                .padding(.horizontal, 16)
                .font(.system(size: 28, design: .default).weight(.medium))
                .autocapitalization(.words)
                .padding(.top, 20)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $localNote.content)
                    .disabled(isLocked)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 100)
                    .font(.system(size: 18, design: .default).weight(.regular))

                if localNote.content.isEmpty {
                    Text("Type something...")
                        .foregroundColor(.black.opacity(0.3))
                        .padding(.top, 8)
                        .padding(.leading, 16)
                        .font(.system(size: 18, design: .default).weight(.medium))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear {
            viewModel.startEditing(note: $originalNote) { isLocked, lockedBy in
                self.isLocked = lockedBy != nil && lockedBy != UserService.getUserId()
            }
            viewModel.listenForSingleNoteUpdates(note: $originalNote) { updatedNote in
                self.localNote = updatedNote
            }
        }
        .onChange(of: localNote.content) { newValue in
            if !isLocked {
                viewModel.updateNote(originalNote, title: localNote.title, content: newValue) { success in
                    if !success {
                        print("Error saving note")
                    }
                }
            }
        }
        .onDisappear {
            viewModel.stopEditing(note: originalNote)
            viewModel.stopListening()
        }
    }
}
