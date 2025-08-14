//
//  CreatePostView.swift
//  BinuApp
//
//  Created by Ryan Toh on 13/6/25.
//

import SwiftUI
import PhotosUI

/**
 View for creating and uploading a new post.
 */
// Displays a “Uploading…” overlay while the network call is in progress.
// Wraps the callback‐based createPost(...) in async/await to ensure the spinner always stops.
// Automatically dismisses on success; shows an alert on failure.

struct CreatePostView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var forumVM: ForumViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var text: String = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var errorText: String?
    @State private var isUploading: Bool = false
    @State private var selectedTopics: [String] = []
    
    let availableTopics = [
        "Period & Cycle", "Mental Health & Self-care", "Health", "Sex Life",
        "My Body", "Relationships", "Self & Society", "Pregnancy"
    ]

    var body: some View {
        ZStack {
            Color("BGColor").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("New Post")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color("FontColor"))
                    .padding(.top)

                // Title
                TextField("Title", text: $title)
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    .foregroundColor(Color("FontColor"))
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.sentences)

                // Body
                TextEditor(text: $text)
                    .frame(height: 160)
                    .padding(10)
                    .background(Color("BGColor"))
                    .cornerRadius(12)
                    .foregroundColor(Color("FontColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("FontColor").opacity(0.1), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden) //  removes white default textbox


                // Photo Picker
                VStack(alignment: .leading, spacing: 10) {
                    PhotosPicker(
                        selection: $photoItems,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Add up to 5 images")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .foregroundColor(Color("FontColor"))
                    }
                    .onChange(of: photoItems) { _ in
                        Task { await loadSelectedImages() }
                    }

                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(selectedImages, id: \.self) { img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                        .shadow(radius: 1)
                                }
                            }
                        }
                    }
                }

                // Error
                if let error = errorText {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 5)
                }
                
                // Topics
                Text("Select up to 3 related topics:")
                    .font(.headline)
                    .foregroundColor(Color("FontColor"))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(availableTopics, id: \.self) { topic in
                        Button(action: {
                            if selectedTopics.contains(topic) {
                                selectedTopics.removeAll { $0 == topic }
                            } else if selectedTopics.count < 3 {
                                selectedTopics.append(topic)
                            }
                        }) {
                            Text(topic)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedTopics.contains(topic) ? Color("FontColor") : .clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color("FontColor"), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(selectedTopics.contains(topic) ? Color("BGColor") : Color("FontColor"))
                        }
                    }
                }


                Spacer()

                // Action Buttons
                HStack(spacing: 20) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)

                    Spacer()

                    Button(action: {
                        Task { await submitPostAsync() }
                    }) {
                        Text("Post")
                            .fontWeight(.bold)
                            .padding()
                            .frame(minWidth: 100)
                            .background(isSubmitDisabled ? Color.gray : Color("FontColor"))
                            .foregroundColor(Color("BGColor"))
                            .cornerRadius(25)
                    }
                    .disabled(isSubmitDisabled || isUploading)
                }
            }
            .padding()
            .disabled(isUploading)

            if isUploading {
                Color.black.opacity(0.4).ignoresSafeArea()

                ProgressView("Uploading…")
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
        .alert("Upload Error", isPresented: Binding<Bool>(
            get: { errorText != nil },
            set: { if !$0 { errorText = nil } }
        )) {
            Button("OK") { errorText = nil }
        } message: {
            Text(errorText ?? "")
        }
    }

    private var isSubmitDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadSelectedImages() async {
        var loaded: [UIImage] = []
        for item in photoItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                loaded.append(uiImage)
            }
        }
        await MainActor.run { selectedImages = loaded }
    }

    private func createPostAsync(userId: String, title: String, text: String, images: [UIImage], topics: [String]) async -> Bool {
        await withCheckedContinuation { continuation in
            forumVM.createPost(userId: userId, title: title, text: text, images: images, topics: topics) { success in
                continuation.resume(returning: success)
            }
        }
    }

    private func submitPostAsync() async {
        await MainActor.run { errorText = nil }

        guard let uid = authVM.user?.id else {
            await MainActor.run { errorText = "You must be signed in to post." }
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty || trimmedText.isEmpty {
            await MainActor.run { errorText = "Title and body cannot be empty." }
            return
        }

        await MainActor.run { isUploading = true }

        let success = await createPostAsync(userId: uid, title: trimmedTitle, text: trimmedText, images: selectedImages, topics: selectedTopics)


        await MainActor.run {
            isUploading = false
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
        .environmentObject(AuthViewModel())
        .environmentObject(ForumViewModel())
}

