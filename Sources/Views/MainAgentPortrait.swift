// ABOUTME: Circular pixel-art portrait of a workstream's main coding agent,
// ABOUTME: replacing the old status dot. Ring color and pulse convey state.

import SwiftUI

/// Sidebar portrait for a workstream's main agent: the harness's pixel
/// character inside a circular state ring. Presence tiers run from full color
/// while working down to near-transparent once dormant.
struct MainAgentPortrait: View {
    let state: WorkstreamAgentStateTracker.AgentRunState
    let isPathValid: Bool
    /// Whether any hook event was seen for this workstream this app launch.
    let hasLiveSession: Bool
    /// Agent type resolving the sprite ("Claude", "OpenCode", …).
    let portraitName: String
    var size: CGFloat = 28

    @State private var isPulsing = false

    var body: some View {
        Group {
            if !isPathValid {
                missingPathPortrait
            } else {
                statefulPortrait
            }
        }
        .frame(width: size, height: size)
        .onAppear { isPulsing = true }
        .onChange(of: pulseDuration) { _, newValue in
            // Restarting the pulse keeps newly swapped ring variants animating.
            guard newValue != nil else { return }
            isPulsing = false
            DispatchQueue.main.async { isPulsing = true }
        }
    }

    // MARK: - State tiers

    @ViewBuilder
    private var statefulPortrait: some View {
        switch state {
        case .working:
            ringedPortrait(color: .green, pulses: true)
                .shadow(color: .green.opacity(isPulsing ? 0.2 : 0.5), radius: 3)
                .accessibilityLabel(Text("Agent is working"))

        case .stalled:
            ringedPortrait(color: .orange, pulses: true)
                .accessibilityLabel(Text("Agent may be stalled"))

        case .needsAttention(.permission):
            ringedPortrait(color: .orange)
                .overlay(alignment: .topTrailing) { permissionBadge }
                .accessibilityLabel(Text("Agent is awaiting permission"))

        case .needsAttention(.justFinished):
            ringedPortrait(color: .blue)
                .accessibilityLabel(Text("Agent finished — needs review"))

        case .idle where hasLiveSession:
            ringedPortrait(color: .secondary, lineWidth: 1)
                .saturation(0.3)
                .opacity(0.8)
                .accessibilityLabel(Text("Agent is idle"))

        case .idle:
            portrait
                .opacity(0.2)
                .accessibilityLabel(Text("Agent is idle"))
        }
    }

    /// Portrait with a state ring; `pulses` fades the ring while active.
    private func ringedPortrait(color: Color, lineWidth: CGFloat = 1.5, pulses: Bool = false) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    color.opacity(pulses && !isPulsing ? 0.35 : 1.0),
                    lineWidth: lineWidth
                )
                .animation(
                    pulses ? .easeInOut(duration: pulseDuration ?? 0.8).repeatForever(autoreverses: true) : nil,
                    value: isPulsing
                )

            portrait
                .padding(1)
        }
    }

    private var missingPathPortrait: some View {
        portrait
            .saturation(0.2)
            .opacity(0.5)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .offset(x: 3, y: -3)
            }
            .accessibilityLabel(Text("Worktree path missing"))
    }

    private var permissionBadge: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: 11))
            .foregroundStyle(.orange)
            .background(Circle().fill(Color.white))
            .offset(x: 4, y: -3)
            .accessibilityHidden(true)
    }

    // MARK: - Pieces

    private var portrait: some View {
        Group {
            if let image = AgentSpriteStore.shared.avatar(name: portraitName, palette: 0, variant: 0) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(Circle())
    }

    /// Pulse period for the current state, nil when the ring is static.
    private var pulseDuration: TimeInterval? {
        switch state {
        case .working: 0.8
        case .stalled: 1.4
        case .needsAttention, .idle: nil
        }
    }
}
