// ABOUTME: View for the run script / dev server in the Environment tab.
// ABOUTME: Shows a terminal for the running server, or start instructions when not configured.

import SwiftUI

func shouldRestoreRunSession(useTmux: Bool, hasRunScript: Bool, hasExistingRunSession: Bool, wasStoppedManually: Bool, isApproved: Bool) -> Bool {
    useTmux && hasRunScript && hasExistingRunSession && !wasStoppedManually && isApproved
}

func scriptCommand(script: String, role: String, shell: String = CommandBuilder.userShell) -> String {
    let inner: String
    if role == "setup" {
        inner = "\(script); printf '\\nSetup completed in this terminal.\\n'"
    } else {
        inner = script
    }
    return "\(shell) -lic \(CommandBuilder.shellQuote(inner, forShell: shell))"
}

/// Derived dev-server status combining the container's `runStarted` flag
/// with the live `PortDetector` state. Previously the panel showed Stop/Rerun
/// (from `runStarted`) over an idle Start button whenever the two disagreed
/// after a workspace switch or a crash — both now derive from one value.
enum RunDisplayStatus: Equatable {
    case idle
    case starting
    case running(port: Int?)
    case stale

    static func resolve(runStarted: Bool, runCommand: String?, portStatus: PortStatus, selectedPort: Int?, isWaiting: Bool) -> RunDisplayStatus {
        guard runStarted, runCommand != nil else {
            // Flag set but no assembled command (or never started).
            return runStarted ? .stale : .idle
        }
        switch portStatus {
        case .running:
            return .running(port: selectedPort)
        case .starting:
            return .starting
        case .none:
            return isWaiting ? .starting : .stale
        }
    }
}

/// Whether the command pins a port. When it does not reference `$FF_PORT`
/// (or any explicit port flag), frameworks fall back to their default port
/// and auto-bump when the old server is still alive — the 8080 -> 8081 creep.
func devCommandReferencesPort(_ command: String) -> Bool {
    if command.contains("FF_PORT") { return true }
    if command.contains("--port") { return true }
    // Match `-p <number>` / `-p<number>` as a standalone flag.
    let pattern = #"(^|\s)-p\s*\d+"#
    if command.range(of: pattern, options: .regularExpression) != nil { return true }
    return false
}

struct EnvironmentTabView: View {
    let workstreamID: UUID
    let workingDirectory: String
    let projectName: String
    let projectDirectory: String
    let workstreamName: String
    let scriptConfig: ScriptConfig
    let useTmux: Bool
    let environmentVars: [String: String]
    /// Final assembled run command (ff-run + tmux wrap), set once the session starts.
    let runCommand: String?
    /// Whether the command comes from the repo config and needs approval.
    let runCommandIsGated: Bool
    /// The resolved dev command when no run script is configured.
    let devCommand: DevCommand?
    @Binding var devCommandOverride: String?
    @Binding var runStoppedManually: Bool
    @Binding var runStarted: Bool
    @Binding var scriptsApproved: Bool
    @Binding var runGeneration: Int
    /// Who started the server (drives the stays-alive hint).
    @Binding var runOwner: RunOwner
    /// Live port state from the container's PortDetector.
    var selectedPort: Int? = nil
    var portStatus: PortStatus = .none
    var expectedPort: Int? = nil
    var isWaitingForServer: Bool = false
    let onStart: () -> Void
    let onStop: () -> Void
    let onRestart: () -> Void

    @EnvironmentObject var surfaceCache: TerminalSurfaceCache
    @EnvironmentObject var appEnv: AppEnvironment
    @State private var isCustomizingDevCommand = false
    @State private var devCommandEditText = ""

    private var runID: UUID {
        derivedUUID(from: workstreamID, salt: "env-run-\(runGeneration)")
    }

    /// The short, human-readable command this pane would run.
    private var runCommandPreference: String? {
        scriptConfig.run ?? devCommand?.command
    }

    /// Single source of truth for what the panel shows: the container's
    /// `runStarted` flag reconciled with the live port state. The header
    /// buttons and the body below both derive from this, so they can never
    /// disagree (Stop/Rerun over an idle Start button).
    private var displayStatus: RunDisplayStatus {
        .resolve(
            runStarted: runStarted,
            runCommand: runCommand,
            portStatus: portStatus,
            selectedPort: selectedPort,
            isWaiting: isWaitingForServer
        )
    }

    /// Stop/Rerun only make sense while a session exists or is coming up.
    /// A stale flag (dead server) offers Start instead.
    private var showsStopControls: Bool {
        switch displayStatus {
        case .starting, .running: return true
        case .idle, .stale: return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let error = scriptConfig.loadError {
                configErrorBanner(error: error)
                Divider()
            }
            if let source = scriptConfig.source, source != ".factoryfloor.json" {
                configSourceBanner(source: source)
                Divider()
            }
            environmentContent
        }
    }

    private var environmentContent: some View {
        runPane()
            .onChange(of: scriptsApproved) { _, approved in
                // Withdrawing approval stops what the repository is already running.
                if !approved, runStarted { onStop() }
            }
            .onAppear {
                restoreRunState()
            }
    }

    @ViewBuilder
    private func runPane() -> some View {
        let title = NSLocalizedString("Run", comment: "")
        let shortcut = "⌘⇧⏎"
        VStack(spacing: 0) {
            HStack {
                if runControlsEnabled, !showsStopControls {
                    Button(action: onStart) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help(NSLocalizedString("Start", comment: ""))
                } else {
                    Image(systemName: "play")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold))

                if let command = runCommandPreference, scriptConfig.run != nil {
                    Text(command)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if runCommandPreference != nil, RunLauncher.executableURL() == nil {
                    Text("No port detection")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                        .help("ff-run helper not found. Run scripts will work but port detection is unavailable.")
                }

                Spacer()

                if runControlsEnabled {
                    if showsStopControls {
                        EnvActionButton(label: NSLocalizedString("Stop", comment: ""), icon: "stop.fill", shortcut: "", action: onStop)
                        EnvActionButton(label: NSLocalizedString("Rerun", comment: ""), icon: "arrow.counterclockwise", shortcut: shortcut, action: onRestart)
                    } else {
                        EnvActionButton(label: NSLocalizedString("Start", comment: ""), icon: "play.fill", shortcut: shortcut, action: onStart)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            if runStarted {
                runStatusRow
                Divider()
            }

            if let warning = portMismatchWarning {
                portWarningRow(warning)
                Divider()
            }

            if scriptConfig.run == nil {
                devCommandSection
                Divider()
            }

            if runCommandIsGated, !scriptsApproved {
                ScriptApprovalView(
                    scriptConfig: scriptConfig,
                    approveLabel: NSLocalizedString("Approve and Start", comment: ""),
                    onApprove: {
                        ScriptTrust.approve(scriptConfig, for: projectDirectory)
                        scriptsApproved = true
                        onStart()
                    }
                )
            } else if showsStopControls, let runCommand {
                SingleTerminalView(
                    surfaceID: runID,
                    workingDirectory: workingDirectory,
                    command: runCommand,
                    isFocused: false,
                    environmentVars: environmentVars
                )
                .id(runID)
            } else if case .stale = displayStatus, runCommandPreference != nil {
                // The server died outside the app (or never materialized):
                // say so explicitly instead of an idle Start button under
                // Stop/Rerun controls.
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("Stopped unexpectedly. Press Start to run it again.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button(action: onStart) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if runCommandPreference != nil {
                VStack(spacing: 12) {
                    Button(action: onStart) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.borderless)
                    if let command = runCommandPreference {
                        Text(command)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    Text(shortcut)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                scriptInstructions(title: title)
            }
        }
    }

    /// Shows the effective dev command (package.json auto-detection or the
    /// user's per-workstream override) and lets the user customize it.
    private var runStatusRow: some View {
        HStack(spacing: 8) {
            switch displayStatus {
            case let .running(port):
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                if let port {
                    Text(String(format: NSLocalizedString("Running on localhost:%@", comment: ""), "\(port)"))
                        .font(.system(size: 12, weight: .medium))
                } else {
                    Text(NSLocalizedString("Running", comment: ""))
                        .font(.system(size: 12, weight: .medium))
                }
                Spacer()
                Text(ownerHint)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            case .starting:
                ProgressView()
                    .controlSize(.small)
                Text(NSLocalizedString("Starting…", comment: ""))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            case .stale:
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text(NSLocalizedString("Stopped unexpectedly", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            case .idle:
                EmptyView()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var ownerHint: String {
        switch runOwner {
        case .info:
            NSLocalizedString("Stays running after browser tabs close", comment: "")
        case .browser:
            NSLocalizedString("Stops when the last browser tab closes", comment: "")
        case .none:
            ""
        }
    }

    /// Warns when the server listens on a different port than the workstream
    /// was assigned. Usually means the dev command ignores `$FF_PORT` and the
    /// framework fell back to its default (or auto-bumped because a leaked
    /// server still holds the expected port).
    private var portMismatchWarning: String? {
        guard case let .running(port) = displayStatus,
              let port, let expectedPort,
              port != expectedPort
        else { return nil }
        return String(
            format: NSLocalizedString("Using port %@ instead of %@. The dev command may ignore $FF_PORT; a leftover server may still hold the expected port.", comment: ""),
            "\(port)", "\(expectedPort)"
        )
    }

    private func portWarningRow(_ warning: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(warning)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.08))
    }

    /// Shows the effective dev command (package.json auto-detection or the
    /// user's per-workstream override) and lets the user customize it.
    private var devCommandSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Dev command")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button(isCustomizingDevCommand ? "Cancel" : "Customize") {
                    if isCustomizingDevCommand {
                        isCustomizingDevCommand = false
                    } else {
                        devCommandEditText = devCommand?.command ?? ""
                        isCustomizingDevCommand = true
                    }
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
            }

            if let devCommand {
                HStack(spacing: 6) {
                    Text(devCommand.command)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    sourceTag(for: devCommand.source)
                }
            } else {
                Text("No dev command found. Add a dev script to package.json or set one below.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if isCustomizingDevCommand {
                HStack(spacing: 6) {
                    TextField("Command", text: $devCommandEditText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                    Button("Save") {
                        let trimmed = devCommandEditText.trimmingCharacters(in: .whitespacesAndNewlines)
                        devCommandOverride = trimmed.isEmpty ? nil : trimmed
                        isCustomizingDevCommand = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if devCommand == nil, !isCustomizingDevCommand {
                Text("Press \u{2318}B to start the dev server and open a browser tab.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            if let command = devCommand?.command, !devCommandReferencesPort(command) {
                Text("Tip: make your dev command listen on $FF_PORT to keep the port stable.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func sourceTag(for source: DevCommand.Source) -> some View {
        let text: String
        switch source {
        case .configScript:
            text = ".factoryfloor.json"
        case .override:
            text = NSLocalizedString("Custom", comment: "")
        case .packageJSON:
            text = NSLocalizedString("From package.json", comment: "")
        }
        return Text(text)
            .font(.system(size: 9, design: .monospaced))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Color.primary.opacity(0.06))
            .clipShape(Capsule())
            .foregroundStyle(.tertiary)
    }

    private func configErrorBanner(error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Failed to load .factoryfloor.json")
                    .font(.system(size: 12, weight: .semibold))
                Text(error)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.yellow.opacity(0.08))
    }

    private func configSourceBanner(source: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
            Text(String(format: NSLocalizedString("Using scripts from %@", comment: ""), source))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(10)
        .background(Color.blue.opacity(0.05))
    }

    private func scriptInstructions(title: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text(String(format: NSLocalizedString("No %@ script configured", comment: ""), title.lowercased()))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text(String(format: NSLocalizedString("Add a %@ field to .factoryfloor.json:", comment: ""), title.lowercased()))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Text("{ \"\(title.lowercased())\": \"your-command\" }")
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var runControlsEnabled: Bool {
        runCommandPreference != nil && (runCommandIsGated ? scriptsApproved : true)
    }

    private func restoreRunState() {
        guard !runStarted,
              useTmux,
              runCommandPreference != nil,
              let tmuxPath = appEnv.toolStatus.tmux.path else { return }
        let session = TmuxSession.sessionName(project: projectName, workstream: workstreamName, role: "run")
        let hasExistingRunSession = TmuxSession.sessionExists(tmuxPath: tmuxPath, sessionName: session)
        // tmux sessions linger with remain-on-exit, so a session alone does
        // not prove the server is alive: require a validated live state too.
        guard hasExistingRunSession, RunStateStore.loadValidated(for: workstreamID) != nil else { return }
        // Dev commands (package.json / override) are never gated.
        let approved = runCommandIsGated ? scriptsApproved : true
        if shouldRestoreRunSession(useTmux: useTmux, hasRunScript: runCommandPreference != nil, hasExistingRunSession: hasExistingRunSession, wasStoppedManually: runStoppedManually, isApproved: approved) {
            runOwner = .info
            runStarted = true
        }
    }
}

extension Notification.Name {
    static let rerunScript = Notification.Name("factoryfloor.rerunScript")
}

private struct EnvActionButton: View {
    let label: String
    let icon: String
    let shortcut: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11))
                Text(shortcut)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isHovering ? Color.primary.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.borderless)
        .onHover { isHovering = $0 }
        .accessibilityLabel(label)
    }
}