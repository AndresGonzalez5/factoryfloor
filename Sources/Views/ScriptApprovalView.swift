// ABOUTME: Approval pane shown before repository-provided scripts are allowed to run.
// ABOUTME: Lists every command and the config file it came from so the user can review it first.

import SwiftUI

struct ScriptApprovalView: View {
    let scriptConfig: ScriptConfig
    let approveLabel: String
    let onApprove: () -> Void
    var secondaryLabel: String?
    var onSecondary: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 30))
                .foregroundStyle(.orange)

            Text("Approve scripts from this repository?")
                .font(.system(size: 15, weight: .semibold))

            Text(explanation)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)

            VStack(alignment: .leading, spacing: 8) {
                commandRow(NSLocalizedString("Setup", comment: ""), scriptConfig.setup)
                commandRow(NSLocalizedString("Run", comment: ""), scriptConfig.run)
                commandRow(NSLocalizedString("Teardown", comment: ""), scriptConfig.teardown)
            }
            .padding(12)
            .frame(maxWidth: 460, alignment: .leading)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack(spacing: 10) {
                if let secondaryLabel, let onSecondary {
                    Button(secondaryLabel, action: onSecondary)
                }
                Button(approveLabel, action: onApprove)
                    .buttonStyle(.borderedProminent)
            }

            Text("Approval covers this repository until the commands change.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var explanation: String {
        guard let source = scriptConfig.source else {
            return NSLocalizedString(
                "These commands come from the repository and run on your machine under your user account.",
                comment: ""
            )
        }
        return String(
            format: NSLocalizedString(
                "These commands come from %@ in the repository and run on your machine under your user account.",
                comment: ""
            ),
            source
        )
    }

    @ViewBuilder
    private func commandRow(_ label: String, _ command: String?) -> some View {
        if let command {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 66, alignment: .leading)
                Text(command)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
