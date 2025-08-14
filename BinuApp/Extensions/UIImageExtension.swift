//
//  UIImageExtension.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//
//

import SwiftUI
import UIKit
import ImageIO

/**
 GIF Loading Support (Unused)
 */
extension UIImage {
    /// Load an animated GIF from the app bundle
    static func gif(name: String) -> UIImage? {
        guard let bundleURL = Bundle.main.url(forResource: name, withExtension: "gif") else {
            print("Gif file \"\(name)\" not found")
            return nil
        }
        guard let data = try? Data(contentsOf: bundleURL) else {
            print("Cannot turn gif into Data")
            return nil
        }
        return animatedImageWithData(data)
    }

    /// Create animated UIImage from GIF data
    private static func animatedImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        // Extract each frame and its delay
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(cgImage)
            }
            let delaySeconds = delayForImageAtIndex(i, source: source)
            delays.append(Int(delaySeconds * 1000)) // convert to ms
        }

        // Compute total duration and frame count based on GCD of delays
        let totalDuration = delays.reduce(0, +)
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()

        for (index, cgImage) in images.enumerated() {
            let frameCount = delays[index] / gcd
            for _ in 0..<frameCount {
                frames.append(UIImage(cgImage: cgImage))
            }
        }

        return UIImage.animatedImage(with: frames, duration: Double(totalDuration) / 1000)
    }

    private static func delayForImageAtIndex(_ index: Int, source: CGImageSource) -> Double {
        let defaultDelay = 0.1
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProps = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return defaultDelay
        }
        if let unclamped = gifProps[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclamped > 0 {
            return unclamped
        }
        if let clamped = gifProps[kCGImagePropertyGIFDelayTime] as? Double, clamped > 0 {
            return clamped
        }
        return defaultDelay
    }

    private static func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        guard let aVal = a, let bVal = b else {
            return a ?? b ?? 0
        }
        var x = aVal
        var y = bVal
        while y != 0 {
            let t = y
            y = x % y
            x = t
        }
        return x
    }

    private static func gcdForArray(_ array: [Int]) -> Int {
        array.reduce(array.first ?? 1) { gcdForPair($0, $1) }
    }
}
