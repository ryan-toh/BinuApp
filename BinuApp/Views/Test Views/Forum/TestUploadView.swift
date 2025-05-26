//
//  TestUploadView.swift
//  BinuApp
//
//  Created by Ryan on 26/5/25.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct TestUploadView: View {
    @State private var selection: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isUploading = false
    @State private var uploadResultMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Display picked image or placeholder
            if let img = selectedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(Text("No Image Selected").foregroundColor(.gray))
            }

            // Photo picker
            PhotosPicker(
                selection: $selection,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Choose Photo", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
            }
            .onChange(of: selection) { newItem in
                Task { @MainActor in
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImg = UIImage(data: data) {
                        selectedImage = uiImg
                    }
                }
            }

            // Upload button
            Button(action: uploadSelectedImage) {
                if isUploading {
                    ProgressView()
                } else {
                    Text("Upload Photo")
                        .bold()
                }
            }
            .disabled(selectedImage == nil || isUploading)

            // Result feedback
            if let msg = uploadResultMessage {
                Text(msg)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func uploadSelectedImage() {
        guard let uiImg = selectedImage else { return }
        isUploading = true
        uploadResultMessage = nil

        // Call your upload API (wrap the single image in an array)
        PostService.create(
            title: "Test Post",
            text: "This is a test upload.",
            images: [uiImg]
        ) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success(let post):
                    uploadResultMessage = "Uploaded post with ID: \(post.id)"
                    selectedImage = nil
                case .failure(let err):
                    uploadResultMessage = "Upload failed: \(err.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    TestUploadView()
}
