// ABOUTME: Compact per-agent mini cards shown under an expanded workstream
// ABOUTME: row while subagents are live in that workstream.

import SwiftUI

/// One mini card per live SUBAGENT run: portrait, name/model, current
/// activity, and either a context meter or elapsed time. The main agent is
/// not listed — its portrait, activity, and context meter live on the
/// workstream row itself. Cards exist exactly while their run is live —
/// Claude Code's stop hooks remove them the moment an agent finishes.
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
                RosterCard(run: run)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onSelect)
            }
            if hiddenCount > 0 {
                Text(String(format: NSLocalizedString("+%d more", comment: "Additional agents beyond the visible roster lines"), hiddenCount))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 28)
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

// MARK: - Single roster card

private struct RosterCard: View {
    let run: WorkstreamAgentStateTracker.AgentRun

    /// Child sessions carry per-run context figures from the harness.
    private var contextUsage: WorkstreamAgentStateTracker.ContextUsage? {
        guard let used = run.contextUsedTokens,
              let limit = run.contextLimitTokens,
              limit > 0 else { return nil }
        return WorkstreamAgentStateTracker.ContextUsage(usedTokens: used, limitTokens: limit)
    }

    var body: some View {
        HStack(spacing: 8) {
            RosterAvatar(name: run.name, palette: run.palette, variant: run.variantIndex, state: run.state)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(run.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let model = run.model {
                        Text(model)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 60, alignment: .leading)
                            .help(run.name + " · " + model)
                            .accessibilityHidden(true)
                    }
                }

                if let activity = run.activity {
                    Text(activity)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                if run.state == .stalled {
                    Text("Stalled")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.orange)
                } else if let usage = contextUsage {
                    ContextMeter(usage: usage)
                } else {
                    ElapsedLabel(startedAt: run.startedAt)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Avatar

private struct RosterAvatar: View {
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
                    .padding(2)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 20, height: 20)
        .onChange(of: state) { _, newValue in
            isPulsing = (newValue == .working)
        }
        .onAppear {
            isPulsing = (state == .working)
        }
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
    }
}

// MARK: - Elapsed time

private struct ElapsedLabel: View {
    let startedAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            Text(Self.elapsed(from: startedAt))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.quaternary)
        }
        .accessibilityHidden(true)
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
