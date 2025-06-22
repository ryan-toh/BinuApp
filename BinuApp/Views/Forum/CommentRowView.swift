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
            Text(comment.userId)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(comment.text)
                .font(.body)
            HStack {
                Spacer()
                Button("Edit", action: onEdit)
                    .font(.caption)
                    .foregroundColor(.blue)
                Button("Delete", action: onDelete)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}
