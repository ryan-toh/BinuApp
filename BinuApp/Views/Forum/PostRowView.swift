//
//  PostRowView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct PostRowView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(post.title)
                .font(.headline)
            
            // Optional image preview (first media item, if any)
            if let firstImage = post.media.first,
               let url = URL(string: firstImage.downloadURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 150)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        Color.gray
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .cornerRadius(8)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            // Body text (limited to 2 lines)
            Text(post.text)
                .font(.subheadline)
                .lineLimit(2)
            
            // Metadata: likes, comments count, sentiment
            HStack(spacing: 16) {
                // Likes
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.subheadline)
                    Text("\(post.likes)")
                        .font(.subheadline)
                }
                
                // Comments
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                    Text("\(post.comments.count)")
                        .font(.subheadline)
                }
                
                // Sentiment
                Text(sentimentEmoji(for: post.sentiment))
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func sentimentEmoji(for sentiment: Sentiment) -> String {
        switch sentiment {
        case .positive: return "😊"
        case .neutral:  return "😐"
        case .negative: return "😟"
        }
    }
}


//#Preview {
//    PostRowView()
//}
