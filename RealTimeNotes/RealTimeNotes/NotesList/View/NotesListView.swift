//
//  NotesListView.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//

import SwiftUI
import FirebaseFirestore

struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var isShowingCreateNoteView = false
    @State private var isShowingEditNoteView = false
    @State private var selectedNote: Note? = nil
    
    private var currentUserId = UserService.getUserId()
    
    private var isEditViewPresented: Binding<Bool> {
        Binding(
            get: { selectedNote != nil },
            set: { if !$0 { selectedNote = nil } }
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Notes List")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingCreateNoteView.toggle()
                    }) {
                        Image("addIcon")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                
                List {
                    ForEach(viewModel.notes) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(note.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer()
                                
                                Text(note.date, style: .date)
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(.gray)
                            }
                            
                            if note.userId == currentUserId {
                                HStack {
                                    Text(note.content)
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    
                                    Spacer()
                                    
                                    Text("You")
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color("neonGreen"))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                            } else {
                                HStack {
                                    Text(note.content)
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            selectedNote = note
                        }
                    }
                    .onDelete(perform: deleteNote)
                }
                .listStyle(PlainListStyle())
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .onAppear {
                viewModel.loadNotes()
                viewModel.listenForUpdates()
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .sheet(isPresented: $isShowingCreateNoteView) {
                CreateNoteView(viewModel: viewModel)
            }
            .sheet(isPresented: isEditViewPresented) {
                if let noteToEdit = selectedNote {
                    EditNotesView(note: Binding(
                        get: { noteToEdit },
                        set: { selectedNote = $0 }
                    ), viewModel: viewModel)
                }
            }

            
        }
    }
    
    private func deleteNote(at offsets: IndexSet) {
        offsets.forEach { index in
            let note = viewModel.notes[index]
            viewModel.deleteNote(note)
        }
    }
}
