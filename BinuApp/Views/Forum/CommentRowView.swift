//
//  CommentRowView.swift
//  BinuApp
//
//  Created by Ryan on 9/6/25.
//

import SwiftUI

struct CommentRowView: View {
    let comment: Comment
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.userId)
                    .font(.subheadline.bold())
                    .foregroundColor(Color("FontColor"))

                Spacer()

                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(90))
                        .padding(.horizontal, 4)
                }
            }

            Text(comment.text)
                .foregroundColor(.black)
                .font(.body)
        }
        .padding()
        .background(Color("BGColor"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}


#Preview {
    CommentRowView(
        comment: Comment(
            id: "1",
            userId: "AwesomeRyan",
            text: "Binu best app to exist for real."
        ),
        onEdit: { print("Edit tapped") },
        onDelete: { print("Delete tapped") }
    )
}
