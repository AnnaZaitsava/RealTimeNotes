//
//  CreateNoteView.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//
//

import SwiftUI

struct CreateNoteView: View {
    @State private var title: String = ""
    @State private var content: String = ""
    @Environment(\.dismiss) var dismiss
    var viewModel: NotesViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding(.leading, 16)
                    }
                    
                    Text("New note")
                        .font(.system(size: 30, weight: .black, design: .default))
                        .foregroundColor(.black)
                        .padding(.leading, 10)
                    Spacer()
                }
                .padding(.top, 20)
                
                TextField("Add title here", text: $title)
                    .padding(.horizontal, 16)
                    .font(.system(size: 28, design: .default).weight(.medium))
                    .autocapitalization(.words)
                    .padding(.top, 20)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $content)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 100)
                        .font(.system(size: 18, design: .default).weight(.regular))
                    if content.isEmpty {
                        Text("Type something...")
                            .foregroundColor(.black.opacity(0.3))
                            .padding(.top, 8)
                            .padding(.leading, 16)
                            .font(.system(size: 18, design: .default).weight(.medium))
                    }
                }

                Spacer()
                
                Button(action: {
                    viewModel.addNote(title: title, content: content)
                    dismiss()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 200)
                        .background(Color("neonGreen"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .padding(.horizontal, 16)
        }
    }
}

struct CreateNoteView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = NotesViewModel()
        return CreateNoteView(viewModel: mockViewModel)
    }
}
