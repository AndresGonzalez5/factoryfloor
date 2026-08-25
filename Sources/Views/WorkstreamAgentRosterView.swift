// ABOUTME: Compact per-agent status lines shown under an expanded workstream
// ABOUTME: row while agents (main or subagents) are live in that workstream.

import SwiftUI

/// One line per live agent run: portrait, name, current activity, elapsed time.
/// Lines exist exactly while their run is live — Claude Code's stop hooks
/// remove them the moment an agent finishes.
struct WorkstreamAgentRosterView: View {
    let runs: [WorkstreamAgentStateTracker.AgentRun]
    /// Called when a roster line is clicked: selects the workstream and
    /// focuses its Coding Agent tab.
    let onSelect: () -> Void

    private static let maxVisibleLines = 4

    private var visibleRuns: [WorkstreamAgentStateTracker.AgentRun] {
        Array(runs.prefix(Self.maxVisibleLines))
    }

    private var hiddenCount: Int {
        max(0, runs.count - Self.maxVisibleLines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(visibleRuns) { run in
                RosterLine(run: run)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onSelect)
            }
            if hiddenCount > 0 {
                Text(String(format: NSLocalizedString("+%d more", comment: "Additional agents beyond the visible roster lines"), hiddenCount))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 20)
                    .onTapGesture(perform: onSelect)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: Text {
        var text = Text("\(runs.count)")
        for run in runs {
            text = text + Text(", ") + Text(run.name)
        }
        return text
    }
}

// MARK: - Single roster line

private struct RosterLine: View {
    let run: WorkstreamAgentStateTracker.AgentRun

    var body: some View {
        HStack(spacing: 5) {
            AvatarWithState(name: run.name, palette: run.palette, variant: run.variantIndex, state: run.state)

            Text(run.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)

            if let model = run.model {
                Text(model)
                    .font(.system(size: 8))
                    .foregroundStyle(.quaternary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 70, alignment: .leading)
                    .help(run.name + " · " + model)
                    .accessibilityHidden(true)
            }

            if let activity = run.activity {
                Text(activity)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 4)

            TrailingStatus(state: run.state, startedAt: run.startedAt)
        }
        .padding(.vertical, 1)
    }
}

// MARK: - Avatar

private struct AvatarWithState: View {
    let name: String?
    let palette: Int
    let variant: Int
    let state: WorkstreamAgentStateTracker.AgentRun.RunState

    @State private var isPulsing = false

    private var ringColor: Color {
        switch state {
        case .working: return .green
        case .stalled: return .orange
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(ringColor.opacity(isPulsing && state == .working ? 0.35 : 0.9), lineWidth: 1)

            if let image = AgentSpriteStore.shared.avatar(name: name, palette: palette, variant: variant) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(1.5)
            } else {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 13, height: 13)
        .onChange(of: state) { _, newValue in
            isPulsing = (newValue == .working)
        }
        .onAppear {
            isPulsing = (state == .working)
        }
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
    }
}

// MARK: - Trailing status

private struct TrailingStatus: View {
    let state: WorkstreamAgentStateTracker.AgentRun.RunState
    let startedAt: Date

    var body: some View {
        Group {
            if state == .stalled {
                Text("Stalled")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.orange)
            } else {
                TimelineView(.periodic(from: .now, by: 30)) { _ in
                    Text(Self.elapsed(from: startedAt))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .accessibilityHidden(state != .stalled)
    }

    private static func elapsed(from start: Date) -> String {
        let interval = max(0, Date().timeIntervalSince(start))
        let minutes = Int(interval) / 60
        if minutes >= 60 {
            return String(format: "%dh%02d", minutes / 60, minutes % 60)
        }
        if minutes >= 1 {
            return String(format: "%dm", minutes)
        }
        return String(format: "%ds", Int(interval))
    }
}
