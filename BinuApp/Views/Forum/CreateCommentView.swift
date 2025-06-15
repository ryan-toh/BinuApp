//
//  CreateCommentView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

struct CreateCommentView: View {
    let postId: String

    @EnvironmentObject private var authVM: AuthViewModel
    @ObservedObject var viewModel: CommentViewModel
    @State private var newCommentText: String = ""
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Leave a Comment")
                        .font(.title2.bold())
                        .foregroundColor(Color("FontColor"))

                    TextField("Type something kind...", text: $newCommentText)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .foregroundColor(Color("FontColor"))
                        .padding(.horizontal)

                    Button(action: {
                        guard let uid = authVM.user?.id else {
                            errorMessage = "You must be signed in to comment."
                            showErrorAlert = true
                            return
                        }

                        let comment = Comment(
                            userId: uid,
                            text: newCommentText
                        )
                        viewModel.createComment(forPostId: postId, comment: comment) { error in
                            if let error = error {
                                errorMessage = error
                                showErrorAlert = true
                            } else {
                                onDismiss()
                            }
                        }
                    }) {
                        Text("Post Comment")
                            .fontWeight(.bold)
                            .foregroundColor(Color("BGColor"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("FontColor"))
                            .cornerRadius(25)
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("New Comment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(Color("FontColor"))
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Oops!"),
                    message: Text(errorMessage ?? "Something went wrong."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}


#Preview {
    let mockAuthVM = AuthViewModel()
    mockAuthVM.user = UserModel(
        id: "mockUser123",
        email: "test@example.com",
        username: "testuser",
        gender: "Female",
        age: 25
    )

    let mockCommentVM = CommentViewModel()

    return CreateCommentView(
        postId: "mockPostId",
        viewModel: mockCommentVM,
        onDismiss: {
            print("Dismissed")
        }
    )
    .environmentObject(mockAuthVM)
}


