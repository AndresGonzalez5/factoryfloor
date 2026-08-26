// ABOUTME: Per-agent mini cards shown under an expanded workstream row while
// ABOUTME: subagents are live in that workstream.

import SwiftUI

/// One card per live SUBAGENT run, mirroring the workstream row's design in
/// miniature: ringed pixel portrait, type name, a status meta line (dot +
/// word · activity · elapsed), and a context bar when the harness reports
/// per-run token figures. The main agent is not listed — its portrait,
/// status line, and context bar live on the workstream row itself. Cards
/// exist exactly while their run is live — Claude Code's stop hooks remove
/// them the moment an agent finishes.
struct WorkstreamAgentRosterView: View {
    let runs: [WorkstreamAgentStateTracker.AgentRun]
    /// Called when a roster line is clicked: selects the workstream and
    /// focuses its Coding Agent tab.
    let onSelect: () -> Void

    private static let maxVisibleLines = 3

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
                    // Clears the 30pt art column so the label aligns with names.
                    .padding(.leading, 36)
                    .onTapGesture(perform: onSelect)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: Text {
        var text = Text("\(runs.count)")
        for run in runs {
            let cap = run.name.capitalizedFirst
            text = text + Text(", ") + Text(cap)
            if let description = run.taskDescription, !description.isEmpty {
                text = text + Text(" — ") + Text(description)
            }
        }
        return text
    }
}

// MARK: - Single roster card

private struct RosterCard: View {
    let run: WorkstreamAgentStateTracker.AgentRun

    /// Child sessions carry per-run context figures from the harness;
    /// cards without them simply render shorter.
    private var contextUsage: WorkstreamAgentStateTracker.ContextUsage? {
        guard let used = run.contextUsedTokens,
              let limit = run.contextLimitTokens,
              limit > 0 else { return nil }
        return WorkstreamAgentStateTracker.ContextUsage(usedTokens: used, limitTokens: limit)
    }

    private var statusColor: Color {
        switch run.state {
        case .working: return .blue
        case .stalled: return .yellow
        }
    }

    private var statusWord: LocalizedStringKey {
        switch run.state {
        case .working: return "Working"
        case .stalled: return "Stalled"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            RosterAvatar(name: run.name, palette: run.palette, variant: run.variantIndex, state: run.state)

            VStack(alignment: .leading, spacing: 3) {
                Text(inlineTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                statusMeta

                if let usage = contextUsage {
                    ContextMeter(usage: usage, style: .bar)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .help(tooltipText)
        .padding(.vertical, 2)
    }

    /// "● Working · Editing Foo.swift · 2m" — same grammar as the workstream
    /// row's status line, driven by this run's own state.
    private var statusMeta: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)
                .padding(.trailing, 4)

            Text(statusWord)
                .foregroundStyle(statusColor)

            if let activity = run.activity {
                metaSeparator
                Text(activity)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            metaSeparator
            ElapsedLabel(startedAt: run.startedAt, fontSize: 9)
        }
        .font(.system(size: 9, design: .monospaced))
        .lineLimit(1)
    }

    private var metaSeparator: some View {
        Text("·")
            .foregroundStyle(.quaternary)
            .padding(.horizontal, 3)
    }

    private var displayName: String {
        run.name.capitalizedFirst
    }

    private var inlineTitle: String {
        if let desc = run.taskDescription, !desc.isEmpty {
            return "\(displayName) — \(desc)"
        }
        return displayName
    }

    private var tooltipText: String {
        var parts = [displayName]
        if let model = run.model, !model.isEmpty { parts.append(model) }
        if let description = run.taskDescription, !description.isEmpty { parts.append(description) }
        return parts.joined(separator: " · ")
    }
}

private extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}

// MARK: - Avatar

private struct RosterAvatar: View {
    let name: String?
    let palette: Int
    let variant: Int
    let state: WorkstreamAgentStateTracker.AgentRun.RunState

    @State private var isPulsing = false

    /// Mirrors MainAgentPortrait's state palette (blue working, yellow stalled).
    private var ringColor: Color {
        switch state {
        case .working: return .blue
        case .stalled: return .yellow
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    ringColor.opacity(isPulsing && state == .working ? 0.35 : 0.9),
                    lineWidth: 1.5
                )

            portrait
                .padding(1)
        }
        .frame(width: 30, height: 30)
        .onChange(of: state) { _, newValue in
            isPulsing = (newValue == .working)
        }
        .onAppear {
            isPulsing = (state == .working)
        }
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
    }

    private var portrait: some View {
        Group {
            if let image = AgentSpriteStore.shared.avatar(name: name, palette: palette, variant: variant) {
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
}

// MARK: - Elapsed time

/// Ticking "4m"-style label counting up from a run's start. Shared by roster
/// cards and the workstream row's status line.
struct ElapsedLabel: View {
    let startedAt: Date
    var fontSize: CGFloat = 8

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            Text(Self.elapsed(from: startedAt))
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundStyle(.quaternary)
        }
        .accessibilityHidden(true)
    }

    static func elapsed(from start: Date) -> String {
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
