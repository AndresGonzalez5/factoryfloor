// ABOUTME: Small horizontal context-window meter (bar + percentage) used on
// ABOUTME: the workstream row for the main agent and on roster cards.

import SwiftUI

/// Compact context-window usage indicator: a 40×3pt capsule bar whose fill
/// turns green → orange → red as the session approaches its context limit.
struct ContextMeter: View {
    let usage: WorkstreamAgentStateTracker.ContextUsage

    private var fraction: Double {
        min(max(usage.fraction, 0), 1)
    }

    private var fillColor: Color {
        if fraction < 0.6 { return .green }
        if fraction < 0.85 { return .orange }
        return .red
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(width: 40, height: 3)
                Capsule()
                    .fill(fillColor)
                    .frame(width: 40 * fraction, height: 3)
            }
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .help(NSLocalizedString("Context window usage", comment: "Tooltip for the per-agent context meter"))
    }
}
