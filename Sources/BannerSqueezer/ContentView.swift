import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Brand palette matching the HTML exactly
private extension Color {
    static let brandBlue      = Color(red: 18/255,  green: 28/255,  blue: 87/255)
    static let brandOrange    = Color(red: 247/255, green: 117/255, blue: 42/255)
    static let brandOrangeDark = Color(red: 234/255, green: 95/255, blue: 35/255)
    static let dropHover      = Color(red: 1,       green: 248/255, blue: 244/255)
}

struct ContentView: View {
    @StateObject private var vm = ViewModel()
    @State private var isDropTargeted = false
    @State private var dashPhase: CGFloat = 0
    @State private var showError = false
    @State private var errorDismissTask: DispatchWorkItem?
    @State private var isDropZoneHovered = false

    // Loaded once — prevents a new NSImage instance every body evaluation
    // which would cause SwiftUI to briefly cross-fade the logo whenever an
    // ambient withAnimation fires (e.g. the error bubble transition).
    private static let logoNSImage: NSImage? = {
        guard let url = Bundle.module.url(forResource: "onu-sano-logo", withExtension: "svg")
        else { return nil }
        return NSImage(contentsOf: url)
    }()

    private static let errorBubbleNSImage: NSImage? = {
        guard let url = Bundle.module.url(forResource: "error-bubble", withExtension: "svg")
        else { return nil }
        return NSImage(contentsOf: url)
    }()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
                // Activate the app on first mouse-enter so the very first button
                // click fires immediately without a separate focus click.
                .onHover { if $0 { NSApp.activate(ignoringOtherApps: true) } }

            VStack(spacing: 20) {
                logo
                dropZone
                CompressButton {
                    if vm.files.isEmpty {
                        showErrorBubble()
                    } else {
                        vm.processFiles()
                    }
                }
            }
            .padding(30)
            .padding(.bottom, 50)

            if vm.showConfetti {
                ConfettiView(onFinish: { vm.showConfetti = false })
                    .allowsHitTesting(false)
            }

            // Always in the hierarchy — opacity + offset driven by showError so
            // both enter and exit are fully animated by SwiftUI's value-based system.
            VStack(spacing: 0) {
                Spacer().frame(height: 162)
                errorBubble
                    .offset(x: -100)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .opacity(showError ? 1 : 0)
            .offset(y: showError ? 0 : -60)
            .animation(.spring(response: 0.35, dampingFraction: 0.55), value: showError)
            .allowsHitTesting(false)
        }
        .frame(width: 800)
        .onAppear {
            // One full dash cycle (8 + 6 = 14 px) over 3 s — seamlessly repeating
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                dashPhase -= 14
            }
        }
    }

    private func showErrorBubble() {
        errorDismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            showError = true
        }
        let task = DispatchWorkItem {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                showError = false
            }
        }
        errorDismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
    }

    // MARK: - Error bubble

    private var errorBubble: some View {
        Group {
            if let img = Self.errorBubbleNSImage {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: 172, height: 82)
            }
        }
    }

    // MARK: - Logo

    private var logo: some View {
        Group {
            if let img = Self.logoNSImage {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
            }
        }
        // Block any ambient withAnimation context from touching the logo
        .transaction { $0.animation = nil }
    }

    // MARK: - Drop zone

    private var dropZone: some View {
        let active = isDropTargeted || isDropZoneHovered
        return ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(active ? Color.dropHover : Color.clear)
                .animation(.easeInOut(duration: 0.3), value: active)

            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandBlue, style: StrokeStyle(lineWidth: 4, dash: [8, 6], dashPhase: dashPhase))

            dropZoneContent
        }
        .frame(height: 400)
        .contentShape(Rectangle())
        .onHover { isDropZoneHovered = $0 }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            vm.addDroppedItems(providers)
            return true
        }
        .onTapGesture {
            if vm.files.isEmpty && !vm.isProcessing { vm.openPicker() }
        }
    }

    @ViewBuilder
    private var dropZoneContent: some View {
        if vm.isProcessing {
            Text(vm.statusMessage)
                .foregroundStyle(Color.brandBlue)
                .font(.system(size: 16))
        } else if vm.files.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.brandBlue)
                    .offset(y: (isDropTargeted || isDropZoneHovered) ? 4 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isDropTargeted || isDropZoneHovered)
                Text("Lohista siia need neetud bännerid!")
                    .foregroundStyle(Color.brandBlue)
                    .font(.system(size: 16))
            }
        } else {
            let label = vm.files.count == 1
                ? "1 fail on valmis pigistuseks"
                : "\(vm.files.count) faili on valmis pigistuseks"
            WiggleText(text: label)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.brandBlue)
        }
    }
}

// MARK: - Wiggle text

// Approximates the After Effects wiggle() expression: random position/rotation
// updated ~7× per second with a soft spring between each keyframe.
private struct WiggleText: View {
    let text: String
    @State private var tx: CGFloat = 0
    @State private var ty: CGFloat = 0
    @State private var rot: Double = 0
    @State private var alive = true

    var body: some View {
        Text(text)
            .offset(x: tx, y: ty)
            .rotationEffect(.degrees(rot))
            .onAppear { wiggle() }
            .onDisappear { alive = false }
    }

    private func wiggle() {
        guard alive else { return }
        withAnimation(.spring(response: 0.14, dampingFraction: 0.35)) {
            tx  = .random(in: -5...5)
            ty  = .random(in: -2...2)
            rot = .random(in: -2.5...2.5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { wiggle() }
    }
}

// MARK: - Compress button

struct CompressButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text("Pigista bännerid")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.brandBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
        .background(buttonBackground)
        .offset(y: isHovered ? -3 : 0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }

    // Stacked Capsule replicates CSS `box-shadow: 0 4px 0 #223387`
    private var buttonBackground: some View {
        ZStack {
            Capsule().fill(Color.brandBlue).offset(y: 4)
            Capsule()
                .fill(isHovered ? Color.brandOrangeDark : Color.brandOrange)
                .overlay(Capsule().stroke(Color.brandBlue, lineWidth: 2))
        }
    }
}
