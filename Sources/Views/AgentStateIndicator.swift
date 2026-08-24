// ABOUTME: Sidebar dot reflecting per-workstream Claude agent state.
// ABOUTME: Working pulses green; permission solid orange; just-finished solid blue.

import SwiftUI

struct AgentStateIndicator: View {
    let state: WorkstreamAgentStateTracker.AgentRunState
    let isPathValid: Bool

    @State private var isPulsing = false

    var body: some View {
        Group {
            if !isPathValid {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.system(size: 10))
                    .accessibilityLabel(Text("Worktree path missing"))
            } else {
                switch state {
                case .working:
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                        .opacity(isPulsing ? 0.4 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear { isPulsing = true }
                        .onChange(of: state) { _, newValue in
                            isPulsing = (newValue == .working || newValue == .stalled)
                        }
                        .accessibilityLabel(Text("Agent is working"))

                case .stalled:
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                        .opacity(isPulsing ? 0.4 : 1.0)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear { isPulsing = true }
                        .accessibilityLabel(Text("Agent may be stalled"))

                case .needsAttention(.permission):
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                        .accessibilityLabel(Text("Agent is awaiting permission"))

                case .needsAttention(.justFinished):
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                        .accessibilityLabel(Text("Agent finished — needs review"))

                case .idle:
                    Circle()
                        .fill(.tertiary)
                        .frame(width: 6, height: 6)
                        .accessibilityLabel(Text("Agent is idle"))
                }
            }
        }
        .frame(width: 12)
    }
}
