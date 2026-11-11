// Copyright 2026 Avida Buyombo
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import AVDCore

public struct GeometricEnergyCoreView: View {
    let state: PresenceState
    let amplitude: CGFloat
    let isReducedMotion: Bool
    
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    public init(state: PresenceState, amplitude: CGFloat = 0.0, isReducedMotion: Bool = false) {
        self.state = state
        self.amplitude = amplitude
        self.isReducedMotion = isReducedMotion
    }
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            let date = timeline.date
            let time = date.timeIntervalSinceReferenceDate
            
            // Dynamic parameters based on real interaction state
            let baseColor = stateColor
            let glowRadius: CGFloat = state == .speaking ? 35 + (amplitude * 25) : (state == .listening ? 30 + (amplitude * 35) : 22)
            let coreScale: CGFloat = state == .listening ? 1.0 + (amplitude * 0.45) : (state == .speaking ? 1.0 + (amplitude * 0.35) : (state == .contemplating ? 1.08 + sin(time * 3.5) * 0.06 : 1.0 + sin(time * 1.5) * 0.04))
            let dynamicRotation = isReducedMotion ? 0 : (state == .contemplating ? time * 45 : time * 12)
            
            ZStack {
                // Outer Atmospheric Aura
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [baseColor.opacity(0.22), baseColor.opacity(0.04), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .scaleEffect(coreScale)
                
                // Concentric Energy Rings
                ForEach(0..<3) { i in
                    let ringScale = 1.0 + CGFloat(i) * 0.28 + (state == .speaking || state == .listening ? amplitude * 0.2 : 0)
                    Circle()
                        .stroke(baseColor.opacity(0.18 - Double(i) * 0.04), lineWidth: 1.2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(ringScale)
                        .rotationEffect(.degrees(dynamicRotation * (i % 2 == 0 ? 1 : -1)))
                }
                
                // Outer Hexagonal Resonance Cage
                Image(systemName: "hexagon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 130, height: 130)
                    .foregroundColor(baseColor.opacity(0.45))
                    .rotationEffect(.degrees(-dynamicRotation * 0.8))
                    .scaleEffect(coreScale * 0.95)
                
                // Inner Geometric Diamond / Hexagon Matrix
                Image(systemName: "rhombus.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(baseColor.opacity(0.35))
                    .rotationEffect(.degrees(dynamicRotation * 1.5))
                    .scaleEffect(coreScale * 0.9)
                
                // Central Awakened Luminous Core
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white, baseColor, baseColor.opacity(0.6)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 36
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: baseColor, radius: glowRadius)
                    .scaleEffect(coreScale)
                
                // State Glyph Indicator in Center
                Image(systemName: stateGlyph)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(WitnessTheme.bgDeep)
                    .scaleEffect(coreScale * 0.85)
            }
        }
    }
    
    private var stateColor: Color {
        switch state {
        case .idle:
            return WitnessTheme.cyanAccent
        case .listening:
            return WitnessTheme.amberAccent
        case .contemplating:
            return WitnessTheme.purpleMemory
        case .speaking:
            return WitnessTheme.cyanAccent
        case .error:
            return WitnessTheme.redAlert
        case .paused:
            return WitnessTheme.textMuted
        }
    }
    
    private var stateGlyph: String {
        switch state {
        case .idle:
            return "hexagon.fill"
        case .listening:
            return "waveform"
        case .contemplating:
            return "sparkles"
        case .speaking:
            return "speaker.wave.3.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .paused:
            return "pause.fill"
        }
    }
}
