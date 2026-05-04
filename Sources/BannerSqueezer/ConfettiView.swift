import SwiftUI
import QuartzCore

struct ConfettiView: View {
    let onFinish: () -> Void

    var body: some View {
        ConfettiEmitterView()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { onFinish() }
            }
    }
}

// MARK: - NSViewRepresentable wrapper

private struct ConfettiEmitterView: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfettiHostView {
        let view = ConfettiHostView()
        // Defer start so the view has a real frame by the time we read bounds
        DispatchQueue.main.async { view.start() }
        return view
    }
    func updateNSView(_ nsView: ConfettiHostView, context: Context) {}
}

// MARK: - Host view

final class ConfettiHostView: NSView {
    // CGImage loaded once; CAEmitterCell.contents requires CGImage
    private static let confettiCGImage: CGImage? = {
        guard let url = Bundle.module.url(forResource: "os-confetti", withExtension: "png"),
              let nsImg = NSImage(contentsOf: url)
        else { return nil }
        var rect = NSRect(origin: .zero, size: nsImg.size)
        return nsImg.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError() }

    func start() {
        // Three bursts at 0 / 0.5 / 1.0 s
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) { [weak self] in
                self?.burst()
            }
        }
    }

    private func burst() {
        guard let hostLayer = layer else { return }

        let emitter = CAEmitterLayer()
        emitter.frame = hostLayer.bounds

        // Non-flipped NSView: y=0 is bottom, y=height is top.
        // We want the emitter at ~60% down from top → 40% from bottom.
        emitter.emitterPosition = CGPoint(x: bounds.width / 2, y: bounds.height * 0.4)
        emitter.emitterShape  = .point
        emitter.emitterSize   = .zero

        let cell = makeCell()
        emitter.emitterCells = [cell]
        hostLayer.addSublayer(emitter)

        // Single burst: emit for 0.15 s then stop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            emitter.birthRate = 0
        }
    }

    private func makeCell() -> CAEmitterCell {
        let cell = CAEmitterCell()

        if let img = Self.confettiCGImage {
            cell.contents = img
            cell.scale      = 0.9
            cell.scaleRange = 0.5
        } else {
            cell.contents   = fallbackCGImage()
            cell.scale      = 1.0
            cell.scaleRange = 0.4
        }

        cell.birthRate    = 100
        cell.lifetime     = 4.0
        cell.lifetimeRange = 1.0

        // Launch upward (positive y in non-flipped CA coords = up)
        cell.emissionLongitude = .pi / 2
        cell.emissionRange     = .pi       // 180° fan upward

        cell.velocity      = 500
        cell.velocityRange = 250

        // Gravity pulling down (negative y in CA y-up coords)
        cell.yAcceleration = -350

        cell.spin      = 8
        cell.spinRange = 16

        cell.alphaSpeed = -0.25
        cell.alphaRange = 0.2

        return cell
    }

    // Fallback: a solid orange rectangle in case the PNG is missing
    private func fallbackCGImage() -> CGImage? {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: 20, height: 14,
                                   bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.setFillColor(NSColor.orange.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: 20, height: 14))
        return ctx.makeImage()
    }
}
