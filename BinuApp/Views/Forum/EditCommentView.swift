//
//  EditCommentView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

struct EditCommentView: View {
    let postId: String
    var comment: Comment

    @EnvironmentObject private var authVM: AuthViewModel
    @ObservedObject var viewModel: CommentViewModel
    @State private var updatedText: String
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    var onDismiss: () -> Void

    init(postId: String, comment: Comment, viewModel: CommentViewModel, onDismiss: @escaping () -> Void) {
        self.postId = postId
        self.comment = comment
        self.viewModel = viewModel
        _updatedText = State(initialValue: comment.text)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    TextField("Edit comment...", text: $updatedText)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(Color("FontColor"))
                        .padding(.horizontal)

                    Button {
                        var edited = comment
                        edited.text = updatedText
                        viewModel.updateComment(forPostId: postId, comment: edited) { error in
                            if let error = error {
                                errorMessage = error
                                showErrorAlert = true
                            } else {
                                onDismiss()
                            }
                        }
                    } label: {
                        Text("Update")
                            .fontWeight(.bold)
                            .foregroundColor(Color("BGColor"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("FontColor"))
                            .cornerRadius(25)
                    }
                    .disabled(updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Edit Comment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(Color("FontColor"))
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    let mockComment = Comment(id: "c1", userId: "user123", text: "Original comment")
    let mockVM = CommentViewModel()
    let mockAuthVM = AuthViewModel()
    mockAuthVM.user = UserModel(id: "user123", email: "mock@example.com", username: "MockUser", gender: "Other", age: 30)

    return EditCommentView(
        postId: "mockPost123",
        comment: mockComment,
        viewModel: mockVM,
        onDismiss: {}
    )
    .environmentObject(mockAuthVM)
}
