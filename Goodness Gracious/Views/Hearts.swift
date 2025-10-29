//
//  Hearts.swift
//  Goodness Gracious
//
//  Created by Vineet Rai on 29-Oct-25.
//
import SwiftUI

import SwiftUI


struct FloatingHeartsView: View {
    struct Heart: Identifiable {
        let id = UUID()
        let xOffset: CGFloat
        let scale: CGFloat
        let rotation: Double
        let color: Color
        let duration: Double
    }

    // Public configuration
    var interval: Double = 0.35
    var horizontalRange: CGFloat = 40
    var verticalDistance: CGFloat = 420
    var baseDuration: Double = 4.0
    var maxHearts: Int = 30   

    @State private var hearts: [Heart] = []
    @State private var timerActive = true

    var body: some View {
        ZStack {
            // hearts stack
            ForEach(hearts) { heart in
                FloteHeartView(heart: heart, verticalDistance: verticalDistance)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .allowsHitTesting(false) // don't block taps under the overlay
        .onReceive(Timer.publish(every: interval, on: .main, in: .common).autoconnect()) { _ in
            guard timerActive else { return }
            spawnHeartIfNeeded()
        }
    }

    private func spawnHeartIfNeeded() {
        guard hearts.count < maxHearts else { return }

        let x = CGFloat.random(in: -horizontalRange...horizontalRange)
        let scale = CGFloat.random(in: 0.7...1.15)
        let rotation = Double.random(in: -25...25)
        let hue = Double.random(in: 0.0...1.0)
        let color = Color(hue: hue, saturation: 0.9, brightness: 0.95)
        let variance = Double.random(in: -0.6...0.6)
        let duration = max(2.0, baseDuration + variance)

        let heart = Heart(xOffset: x, scale: scale, rotation: rotation, color: color, duration: duration)
        hearts.append(heart)

        // remove after animation ends
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.25) {
            withAnimation(.linear(duration: 0.25)) {
                hearts.removeAll { $0.id == heart.id }
            }
        }
    }

    // Public controls
    func stop() {
        timerActive = false
    }

    func start() {
        timerActive = true
    }
}

private struct FloteHeartView: View {
    let heart: FloatingHeartsView.Heart
    let verticalDistance: CGFloat

    @State private var animate = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 28))
            .scaleEffect(animate ? heart.scale : (heart.scale * 0.6))
            .rotationEffect(.degrees(heart.rotation))
            .opacity(animate ? 0.0 : 1.0)
            .offset(x: heart.xOffset, y: animate ? -verticalDistance : 0)
            .foregroundColor(heart.color)
            .shadow(radius: 2)
            .onAppear {
                // small pop then float up
                withAnimation(Animation.easeOut(duration: 0.18)) {
                    animate = false
                }
                // start floating after a tiny delay so pop is visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(Animation.easeInOut(duration: heart.duration)) {
                        animate = true
                    }
                }
            }
    }
}

// MARK: - Preview / Example Usage

struct FloatingHearts_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                Text("Tap ❤️ to send hearts")
                    .foregroundColor(.white)
                    .padding(.bottom, 220)
            }

            FloatingHeartsView(interval: 0.2, horizontalRange: 120, verticalDistance: 380, baseDuration: 4.2)
        }
    }
}

