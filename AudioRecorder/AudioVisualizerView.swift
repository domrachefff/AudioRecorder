//
//  AudioVisualizerView.swift
//  AudioRecorder
//
//  Created by Алексей on 13.12.2024.
//
import SwiftUI

struct AudioVisualizerView: View {
    @Binding var audioLevel: CGFloat

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { index in
                    Capsule()
                        .fill(Color.blue)
                        .frame(
                            width: (geometry.size.width / 20) - 4,
                            height: CGFloat.random(in: 0.1...1.0) * geometry.size.height * self.audioLevel
                        )
                        .animation(.linear(duration: 0.1), value: audioLevel)
                }
            }
            .frame(height: geometry.size.height)
        }
    }
}

