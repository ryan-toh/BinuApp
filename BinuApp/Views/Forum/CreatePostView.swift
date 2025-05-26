//
//  CreatePostView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var forumVM: ForumViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var text: String = ""
    
    // Use the new PhotosPicker API (iOS 17+)
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    
    @State private var errorText: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Title")) {
                    TextField("Enter post title", text: $title)
                }
                
                Section(header: Text("Body")) {
                    TextEditor(text: $text)
                        .frame(minHeight: 150)
                }
                
                Section(header: Text("Images (optional)")) {
                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Select up to 5 photos")
                        }
                    }
                    .onChange(of: photoItems) { _ in
                        Task { await loadSelectedImages() }
                    }
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedImages, id: \.self) { img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if let error = errorText {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Post")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        submitPost()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty ||
                              text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    /// Load UIImages from `photoItems` asynchronously.
    private func loadSelectedImages() async {
        var loaded: [UIImage] = []
        for item in photoItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                loaded.append(uiImage)
            }
        }
        // Assign on main thread
        await MainActor.run { selectedImages = loaded }
    }
    
    /// Validate inputs and call `forumVM.createPost(...)`
    private func submitPost() {
        guard let uid = authVM.currentUser?.uid else {
            errorText = "You must be signed in to post."
            return
        }
        
        if title.trimmingCharacters(in: .whitespaces).isEmpty ||
           text.trimmingCharacters(in: .whitespaces).isEmpty {
            errorText = "Title and body cannot be empty."
            return
        }
        
        forumVM.createPost(userId: uid, title: title, text: text, images: selectedImages) { success in
            if success {
                dismiss()
            } else {
                errorText = forumVM.errorMessage
            }
        }
    }
}


#Preview {
    CreatePostView()
}
