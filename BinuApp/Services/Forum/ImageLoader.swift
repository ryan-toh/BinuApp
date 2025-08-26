//
//  ImageLoader.swift
//  Binu
//
//  Created by Ryan on 26/8/25.
//


// 1) Add these helpers once (e.g., in the same file or a shared file)

import SwiftUI

@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var currentURL: URL?

    func load(from url: URL) async {
        // Skip if already loaded for this URL
        guard url != currentURL || image == nil else { return }
        currentURL = url

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)

        // Try cache first
        if let cached = URLCache.shared.cachedResponse(for: request)?.data,
           let img = UIImage(data: cached) {
            self.image = img
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return }
            if let img = UIImage(data: data) {
                let cached = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cached, for: request)
                self.image = img
            }
        } catch {
            // If cancelled during fast scroll, task(id:) will retry on reappear.
        }
    }
}
