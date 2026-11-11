// Copyright 2026 Avida Buyombo
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import AppKit

public struct WitnessKanjiMark: View {
    let size: CGFloat
    let glowColor: Color
    let opacity: Double
    
    public init(size: CGFloat = 32, glowColor: Color = WitnessTheme.cyanAccent, opacity: Double = 1.0) {
        self.size = size
        self.glowColor = glowColor
        self.opacity = opacity
    }
    
    public var body: some View {
        if let image = loadKanjiImage() {
            Image(nsImage: image)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(glowColor)
                .frame(width: size, height: size)
                .opacity(opacity)
                .shadow(color: glowColor.opacity(0.4), radius: size * 0.15)
        } else {
            // Fallback to text character if asset not found
            Text("見")
                .font(.system(size: size * 0.8, weight: .bold))
                .foregroundColor(glowColor)
                .shadow(color: glowColor.opacity(0.4), radius: size * 0.15)
        }
    }
    
    private func loadKanjiImage() -> NSImage? {
        let possiblePaths = [
            Bundle.main.path(forResource: "witness_kanji_cyan", ofType: "png", inDirectory: "Assets"),
            Bundle.main.path(forResource: "witness_kanji_cyan", ofType: "png"),
            "/Users/ahhveedaa/.openclaw/workspace/AVD-AI-macOS/Resources/Assets/witness_kanji_cyan.png"
        ]
        
        for path in possiblePaths.compactMap({ $0 }) {
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }
}
