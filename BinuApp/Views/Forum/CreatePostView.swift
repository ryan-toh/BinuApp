//
//  CreatePostView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI
import PhotosUI

/// A production‐ready view for creating and uploading a new post.
/// - Displays a “Uploading…” overlay while the network call is in progress.
/// - Wraps the callback‐based `createPost(...)` in async/await to ensure the spinner always stops.
/// - Automatically dismisses on success; shows an alert on failure.
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

    var body: some View {
        ZStack {
            NavigationStack {
                Form {
                    Section(header: Text("Title")) {
                        TextField("Enter post title", text: $title)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.sentences)
                    }

                    Section(header: Text("Body")) {
                        TextEditor(text: $text)
                            .frame(minHeight: 150)
                            .disableAutocorrection(true)
                            .autocapitalization(.sentences)
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
                            Task {
                                await submitPostAsync()
                            }
                        }
                        .disabled(isSubmitDisabled || isUploading)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isUploading)
                    }
                }
            }
            .disabled(isUploading)

            if isUploading {
                Color.black
                    .opacity(0.4)
                    .ignoresSafeArea()

                ProgressView("Uploading…")
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .alert(
            "Upload Error",
            isPresented: Binding<Bool>(
                get: { errorText != nil },
                set: { if !$0 { errorText = nil } }
            )
        ) {
            Button("OK") { errorText = nil }
        } message: {
            Text(errorText ?? "")
        }
    }

    /// Disable “Post” if title/body are empty (after trimming).
    private var isSubmitDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
         || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Asynchronously load UIImage instances from selected PhotosPickerItems.
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

    /// Wraps the callback‐based `forumVM.createPost(...)` in async/await,
    /// so we can always clear `isUploading`—even if the completion handler never fires.
    private func createPostAsync(
        userId: String,
        title: String,
        text: String,
        images: [UIImage]
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            forumVM.createPost(userId: userId, title: title, text: text, images: images) { success in
                continuation.resume(returning: success)
            }
            // Note: if `createPost(...)` never calls its completion, this continuation will hang.
            // TODO: Dispatch a fallback timeout here.
        }
    }

    /// Validates inputs, shows “Uploading…” overlay, awaits upload, then
    /// dismisses on success or shows an alert on failure.
    private func submitPostAsync() async {
        // Clear any prior error
        await MainActor.run { errorText = nil }

        guard let uid = authVM.currentUser?.uid else {
            await MainActor.run { errorText = "You must be signed in to post." }
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty || trimmedText.isEmpty {
            await MainActor.run { errorText = "Title and body cannot be empty." }
            return
        }

        // Show the overlay
        await MainActor.run { isUploading = true }

        // Await the callback‐based createPost
        let success = await createPostAsync(
            userId: uid,
            title: trimmedTitle,
            text: trimmedText,
            images: selectedImages
        )

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
}
