// ABOUTME: Horizontal context-window meter (bar + percentage) used on the
// ABOUTME: workstream row and on roster subagent cards.

import SwiftUI

/// Context-window usage indicator whose fill color reflects the worse of two
/// pressures, staying deliberately neutral while healthy so it never pulls
/// attention:
///
/// - *Capacity*: share of the (inferred) model window — gray <60%,
///   orange <85%, red at/above.
/// - *Quality*: absolute token count — past
///   `ContextLimits.qualityCautionThreshold` (~200k) the color floors at
///   orange, past `qualityCriticalThreshold` (300k) at red, because response
///   quality decays in absolute terms even when a large window still has room.
///
/// - `.compact`: fixed 40×3pt capsule with a % label beneath (roster cards).
/// - `.bar`: flexible track filling the available width with a
///   "12.3k · 6%" label trailing (workstream row).
struct ContextMeter: View {
    enum Style {
        case compact
        case bar
    }

    let usage: WorkstreamAgentStateTracker.ContextUsage
    var style: Style = .compact

    private var fraction: Double {
        min(max(usage.fraction, 0), 1)
    }

    // MARK: Severity

    /// 0 = green, 1 = orange, 2 = red. Internal + pure for unit testing.
    ///
    /// Quality thresholds are absolute, not relative to the window: past
    /// 200k the meter reads orange even on a roomy window, past 300k red —
    /// response quality decays in absolute terms long before a large
    /// window is actually full. Capacity escalates independently.
    static func severity(fraction: Double, usedTokens: Int) -> Int {
        var severity = 0
        if fraction >= 0.85 {
            severity = 2
        } else if fraction >= 0.6 {
            severity = 1
        }
        if usedTokens >= ContextLimits.qualityCautionThreshold {
            severity = max(severity, 1)
        }
        if usedTokens >= ContextLimits.qualityCriticalThreshold {
            severity = max(severity, 2)
        }
        return severity
    }

    /// Gray (calm) / orange / red. Internal + pure for unit testing.
    ///
    /// Gray on purpose: a healthy meter is uninteresting information and
    /// shouldn't compete with the state colors elsewhere in the sidebar.
    static func severityColor(_ severity: Int) -> Color {
        [.gray, .orange, .red][min(max(severity, 0), 2)]
    }

    private var fillColor: Color {
        Self.severityColor(Self.severity(fraction: fraction, usedTokens: usage.usedTokens))
    }

    // MARK: Labels

    private var percentLabel: String {
        "\(Int(fraction * 100))%"
    }

    /// Compact token count: 999 → "999", 12_340 → "12.3k",
    /// 145_234 → "145k", 1_234_567 → "1.2M".
    static func compactTokenCount(_ tokens: Int) -> String {
        let tokens = max(tokens, 0)
        switch tokens {
        case ..<1_000: return "\(tokens)"
        case ..<100_000: return String(format: "%.1fk", Double(tokens) / 1_000)
        case ..<1_000_000: return "\(tokens / 1_000)k"
        default: return String(format: "%.1fM", Double(tokens) / 1_000_000)
        }
    }

    /// "12.3k · 6%" — the row bar's trailing label.
    private var barLabel: String {
        "\(Self.compactTokenCount(usage.usedTokens)) · \(percentLabel)"
    }

    var body: some View {
        switch style {
        case .compact:
            VStack(alignment: .trailing, spacing: 2) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                        .frame(width: 40, height: 3)
                    Capsule()
                        .fill(fillColor)
                        .frame(width: 40 * fraction, height: 3)
                }
                Text(percentLabel)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .help(helpText)

        case .bar:
            HStack(spacing: 4) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                        Capsule()
                            .fill(fillColor)
                            .frame(width: max(0, proxy.size.width * fraction))
                    }
                }
                .frame(height: 3)
                Text(barLabel)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            .help(barHelpText)
        }
    }

    private var helpText: String {
        NSLocalizedString("Context window usage", comment: "Tooltip for the per-agent context meter")
    }

    private var barHelpText: String {
        String(
            format: NSLocalizedString(
                "Context: %1$lld tokens · %2$lld%%",
                comment: "Tooltip for the workstream context bar: exact token count and percent of window"),
            usage.usedTokens,
            Int(fraction * 100))
    }
}
