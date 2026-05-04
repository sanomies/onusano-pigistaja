import SwiftUI
import AppKit

@main
struct BannerSqueezerApp: App {
    @State private var showSplash = true
    @State private var showUI     = false

    var body: some Scene {
        WindowGroup("Bänneripigistaja") {
            ZStack {
                Color.white.ignoresSafeArea()

                ContentView()
                    .scaleEffect(showUI ? 1.0 : 0.8)
                    .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.8), value: showUI)
                    .overlay {
                        Color.white
                            .ignoresSafeArea()
                            .opacity(showUI ? 0 : 1)
                            .animation(.linear(duration: 0.8), value: showUI)
                            .allowsHitTesting(false)
                    }

                if showSplash {
                    SplashView {
                        showSplash = false
                        showUI     = true
                        if let win = NSApplication.shared.keyWindow {
                            NSAnimationContext.runAnimationGroup { ctx in
                                ctx.duration = 0.8
                                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                                [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton]
                                    .compactMap { win.standardWindowButton($0) }
                                    .forEach { $0.animator().alphaValue = 1 }
                            }
                        }
                    }
                }
            }
            .background(WindowConfigurator())
        }
        .windowResizability(.contentSize)
    }
}

// NSViewRepresentable is the only reliable way to access the host window —
// `NSApplication.shared.keyWindow` can be nil during early launch.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let probe = NSView()
        DispatchQueue.main.async { Self.configure(probe.window) }
        return probe
    }
    func updateNSView(_ nsView: NSView, context: Context) {}

    static func configure(_ win: NSWindow?) {
        guard let win else { return }

        win.titlebarAppearsTransparent  = true
        win.titleVisibility             = .hidden
        win.titlebarSeparatorStyle      = .none
        win.styleMask.insert(.fullSizeContentView)
        win.isMovableByWindowBackground = true
        win.isOpaque        = false
        win.backgroundColor = .clear

        if let cv = win.contentView {
            cv.wantsLayer           = true
            cv.layer?.cornerRadius  = 16
            cv.layer?.masksToBounds = true
        }

        guard let themeFrame  = win.contentView?.superview,
              let contentView = win.contentView,
              let closeBtn    = win.standardWindowButton(.closeButton),
              let minBtn      = win.standardWindowButton(.miniaturizeButton),
              let zoomBtn     = win.standardWindowButton(.zoomButton),
              let titlebarView = closeBtn.superview,   // NSTitlebarView
              let container    = titlebarView.superview // NSTitlebarContainerView
        else { return }

        // Root cause: NSTitlebarContainerView sits above the SwiftUI contentView
        // in NSThemeFrame's subview array, so it always renders on top.
        // Fix: promote contentView above the title bar container, then move the
        // traffic-light buttons even higher so they float above the white content.

        // 1. Raise contentView to the top of NSThemeFrame's z-order.
        themeFrame.addSubview(contentView, positioned: .above, relativeTo: nil)

        // 2. Capture button positions before re-parenting.
        let closeFr = themeFrame.convert(closeBtn.frame, from: titlebarView)
        let minFr   = themeFrame.convert(minBtn.frame,   from: titlebarView)
        let zoomFr  = themeFrame.convert(zoomBtn.frame,  from: titlebarView)

        // 3. Move traffic lights to NSThemeFrame above the content view.
        // Switch off Auto Layout (translatesAutoresizingMaskIntoConstraints is false
        // by default on these system buttons, which silently ignores autoresizingMask).
        for btn in [closeBtn, minBtn, zoomBtn] {
            themeFrame.addSubview(btn, positioned: .above, relativeTo: nil)
            btn.translatesAutoresizingMaskIntoConstraints = true
            btn.autoresizingMask = [.minYMargin, .maxXMargin]
        }
        closeBtn.frame = closeFr
        minBtn.frame   = minFr
        zoomBtn.frame  = zoomFr

        // 4. Hide the now-empty title bar container.
        container.isHidden = true

        // Hard backstop: re-pin buttons after every resize in case AppKit re-runs
        // layout and overrides our frames (e.g. full-screen transitions, Live Resize).
        let h0          = themeFrame.frame.height
        let closeTopGap = h0 - closeFr.maxY
        let minTopGap   = h0 - minFr.maxY
        let zoomTopGap  = h0 - zoomFr.maxY
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification, object: win, queue: .main
        ) { [weak themeFrame, weak closeBtn, weak minBtn, weak zoomBtn, weak container] _ in
            guard let tf = themeFrame else { return }
            let h = tf.frame.height
            closeBtn?.frame = CGRect(x: closeFr.minX, y: h - closeTopGap - closeFr.height,
                                     width: closeFr.width, height: closeFr.height)
            minBtn?.frame   = CGRect(x: minFr.minX,   y: h - minTopGap   - minFr.height,
                                     width: minFr.width,   height: minFr.height)
            zoomBtn?.frame  = CGRect(x: zoomFr.minX,  y: h - zoomTopGap  - zoomFr.height,
                                     width: zoomFr.width,  height: zoomFr.height)
            container?.isHidden = true
        }

        // Traffic lights start hidden; SplashView fades them in on completion.
        [closeBtn, minBtn, zoomBtn].forEach { $0.alphaValue = 0 }
    }
}
