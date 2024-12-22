//
//  NotesListView.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//
import SwiftUI

struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var isShowingCreateNoteView = false
    private var currentUserId = UserService.getUserId()
    
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
        }
    }
    
    private func deleteNote(at offsets: IndexSet) {
        offsets.forEach { index in
            let note = viewModel.notes[index]
            viewModel.deleteNote(note) // Вызов функции удаления заметки из ViewModel
        }
    }
}


//
//import SwiftUI
//struct NotesListView: View {
//    @StateObject private var viewModel = NotesViewModel()
//    @State private var isShowingCreateNoteView = false
//    private var currentUserId = UserService.getUserId()
//
//
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(viewModel.notes) { note in
//                    HStack {
//                        Text(note.title)
//                        Spacer()
//
//                        if note.userId == currentUserId {
//                            Text("You")
//                                .foregroundColor(.gray)
//                        }
//                    }
//                    .swipeActions {
//                        Button(role: .destructive) {
//                            viewModel.deleteNote(note)
//                        } label: {
//                            Label("Delete", systemImage: "trash")
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Notes List")
//            .onAppear {
//                viewModel.loadNotes()
//                viewModel.listenForUpdates()
//            }
//            .onDisappear {
//                viewModel.stopListening()
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        isShowingCreateNoteView.toggle()
//                    }) {
//                        Image("addIcon")
//                            .resizable()
//                            .frame(width: 50, height: 50)
//                            .padding(.trailing, 16)
//                    }
//                }
//            }
//            .sheet(isPresented: $isShowingCreateNoteView) {
//                CreateNoteView(viewModel: viewModel)
//            }
//        }
//    }
//}


