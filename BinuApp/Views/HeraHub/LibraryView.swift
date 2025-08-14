//
//  LibraryView.swift
//  BinuApp
//
//  Created by Hong Eungi on 24/7/25.
//

import SwiftUI

/**
 Shows RSS Feeds from WHO & CNA using methods and published variables from LibraryViewModel
 */
struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 24) {
                        Image("watercolourLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color("FontColor").opacity(0.15), lineWidth: 1)
                            )
                            .shadow(radius: 3, y: 2)
                            .padding()
                        
                        // WHO Section
                        Text("Understand from WHO...")
                            .font(.title3.bold())
                            .foregroundColor(Color("FontColor"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        HorizontalCardScroll(items: viewModel.summaries) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.category)
                                    .font(.caption)
                                    .foregroundColor(Color("BGColor"))

                                Text(item.title)
                                    .font(.subheadline).bold()
                                    .foregroundColor(Color("BGColor"))

                                Text(item.summary)
                                    .font(.footnote)
                                    .foregroundColor(.black)
                                    .lineLimit(3)

                                if let url = URL(string: item.source) {
                                    Link("Read more on WHO", destination: url)
                                        .font(.caption)
                                        .foregroundColor(Color("BGColor"))
                                }
                            }
                            .padding()
                            .frame(width: 280, height: 180)
                            .background(Color("FontColor"))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }

                        // UN Women
                        SectionHeader("UN Women: Stay updated about women's health issues globally...")
                            .onAppear {
                                viewModel.loadUNFeedIfNeeded()
                            }

                        if viewModel.unWomenCards.isEmpty && !viewModel.didLoadUN {
                            ProgressView("Loading UN Women feed...")
                                .foregroundColor(Color("FontColor"))
                                .padding(.horizontal)
                        } else {
                            HorizontalCardScroll(items: viewModel.unWomenCards) { card in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(card.title)
                                        .foregroundColor(Color("FontColor"))
                                        .font(.subheadline).bold()
                                    if let url = URL(string: card.link ?? "") {
                                        Link("Read more...", destination: url)
                                            .font(.footnote)
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding()
                                .frame(width: 280, height: 120)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                            }
                        }

                        // CNA
                        SectionHeader("CNA: Stay updated about women's health issues in Singapore...")
                            .onAppear {
                                viewModel.loadCNAFeedIfNeeded()
                            }

                        if viewModel.cnaCards.isEmpty && !viewModel.didLoadCNA {
                            ProgressView("Loading CNA feed...")
                                .foregroundColor(Color("FontColor"))
                                .padding(.horizontal)
                        } else {
                            HorizontalCardScroll(items: viewModel.cnaCards) { card in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(card.title)
                                        .foregroundColor(Color("FontColor"))
                                        .font(.subheadline).bold()
                                    if let url = URL(string: card.link ?? "") {
                                        Link("Read more...", destination: url)
                                            .font(.footnote)
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding()
                                .frame(width: 280, height: 120)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
                .refreshable {
                    viewModel.didLoadUN = false
                    viewModel.didLoadCNA = false
                    viewModel.loadUNFeedIfNeeded()
                    viewModel.loadCNAFeedIfNeeded()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("HeraHub Library")
                        .font(.title.bold())
                        .foregroundColor(Color("FontColor"))
                }
            }
        }
    }

    @ViewBuilder
    private func SectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(Color("FontColor"))
            .padding(.horizontal)
    }

    private func HorizontalCardScroll<T: Identifiable, Content: View>(
        items: [T],
        @ViewBuilder content: @escaping (T) -> Content
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items) { item in
                    content(item)
                }
            }
            .padding(.horizontal)
        }
    }
}
