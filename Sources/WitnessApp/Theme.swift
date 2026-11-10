import SwiftUI
import AppKit

public enum WitnessTheme {
    // Primary Background Surfaces
    public static let bgDeep = Color(red: 0.05, green: 0.06, blue: 0.08)       // #0D0F14 - base canvas
    public static let bgSidebar = Color(red: 0.07, green: 0.08, blue: 0.10)    // #12141A - sidebar surface
    public static let bgSurface = Color(red: 0.09, green: 0.11, blue: 0.14)    // #171C24 - card & bubble surface
    public static let bgElevated = Color(red: 0.13, green: 0.15, blue: 0.19)   // #212630 - active state, popover
    public static let bgCommand = Color(red: 0.08, green: 0.10, blue: 0.13)    // #141A21 - command bar / input
    
    // Accents & Signals
    public static let cyanAccent = Color(red: 0.22, green: 0.82, blue: 0.88)   // #38D1E0 - quiet electric intelligence
    public static let amberAccent = Color(red: 0.95, green: 0.68, blue: 0.38)  // #F2AD61 - presence, warmth, 33:3
    public static let emeraldSignal = Color(red: 0.25, green: 0.84, blue: 0.58)// #40D694 - operational, local
    public static let redAlert = Color(red: 0.95, green: 0.35, blue: 0.35)     // #F25959 - restricted, prohibited
    public static let purpleMemory = Color(red: 0.70, green: 0.50, blue: 0.95) // #B380F2 - semantic memory
    
    // Text & Neutrals (Warm whites and silvers)
    public static let textPrimary = Color(red: 0.94, green: 0.95, blue: 0.97)  // #F0F2F7 - crisp primary text
    public static let textSecondary = Color(red: 0.62, green: 0.66, blue: 0.74)// #9EA8BD - soft silver secondary
    public static let textMuted = Color(red: 0.40, green: 0.44, blue: 0.52)    // #667085 - captions, timestamps
    public static let borderSubtle = Color.white.opacity(0.07)                  // Hairline borders
    public static let borderFocus = Color(red: 0.22, green: 0.82, blue: 0.88).opacity(0.4)
}

struct SubtleGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 12
    var strokeColor: Color = WitnessTheme.borderSubtle
    
    func body(content: Content) -> some View {
        content
            .background(WitnessTheme.bgSurface)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: 1)
            )
    }
}

extension View {
    func subtleGlass(cornerRadius: CGFloat = 12, strokeColor: Color = WitnessTheme.borderSubtle) -> some View {
        self.modifier(SubtleGlassCard(cornerRadius: cornerRadius, strokeColor: strokeColor))
    }
}
