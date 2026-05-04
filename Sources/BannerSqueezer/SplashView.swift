import SwiftUI
import AVKit

struct SplashView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.white
            if let url = Bundle.module.url(forResource: "onusano-splash", withExtension: "mp4") {
                SplashPlayerView(url: url, onFinish: onFinish)
                    .frame(width: 500, height: 500)
            } else {
                // Video not found — skip straight to main UI
                Color.white.onAppear { onFinish() }
            }
        }
    }
}

// MARK: - AVPlayerLayer wrapper
// Using AVPlayerLayer directly (not AVPlayerView) so we own the backing CALayer
// and can guarantee the letterbox areas are #FFFFFF.

private struct SplashPlayerView: NSViewRepresentable {
    let url: URL
    let onFinish: () -> Void

    func makeNSView(context: Context) -> PlayerHostView {
        let player = AVPlayer(url: url)

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.didFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )

        let host = PlayerHostView(player: player)
        player.play()
        return host
    }

    func updateNSView(_ nsView: PlayerHostView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

        @objc func didFinish() {
            DispatchQueue.main.async { self.onFinish() }
        }
    }
}

final class PlayerHostView: NSView {
    private let playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.white.cgColor
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { .init(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric) }

    override func layout() {
        super.layout()
        // Keep player layer filling the view; CALayer doesn't auto-resize
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
