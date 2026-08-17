// ABOUTME: Watches ff-run state files and publishes the selected port for a workstream.
// ABOUTME: Uses filesystem events instead of polling so browser targets update immediately.

import Foundation

/// Lifecycle of the ff-run session for a workstream.
enum PortStatus: Equatable, Sendable {
    /// No ff-run session is alive (server not running).
    case none
    /// A session is running but no port has been selected yet.
    case starting
    /// A listening port has been selected; the server is reachable.
    case running
}

final class PortDetector: ObservableObject, @unchecked Sendable {
    @Published private(set) var selectedPort: Int?
    @Published private(set) var status: PortStatus = .none

    private let workstreamID: UUID
    private let queue: DispatchQueue
    private var directorySource: DispatchSourceFileSystemObject?
    private var fileSource: DispatchSourceFileSystemObject?

    init(workstreamID: UUID) {
        self.workstreamID = workstreamID
        self.queue = DispatchQueue(label: "factoryfloor.port-detector.\(workstreamID.uuidString.lowercased())")
        start()
    }

    deinit {
        stop()
    }

    private func start() {
        try? FileManager.default.createDirectory(at: RunStateStore.directoryURL, withIntermediateDirectories: true)
        attachDirectoryWatcher()
        refreshState()
    }

    private func stop() {
        fileSource?.cancel()
        fileSource = nil
        directorySource?.cancel()
        directorySource = nil
    }

    private func attachDirectoryWatcher() {
        let directoryPath = RunStateStore.directoryURL.path
        let descriptor = open(directoryPath, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.attrib, .delete, .extend, .rename, .write],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            self?.attachFileWatcherIfNeeded()
            self?.refreshState()
        }
        source.setCancelHandler {
            close(descriptor)
        }
        directorySource = source
        source.resume()

        attachFileWatcherIfNeeded()
    }

    private func attachFileWatcherIfNeeded() {
        let statePath = RunStateStore.fileURL(for: workstreamID).path
        guard FileManager.default.fileExists(atPath: statePath) else {
            fileSource?.cancel()
            fileSource = nil
            return
        }
        guard fileSource == nil else { return }

        let descriptor = open(statePath, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.attrib, .delete, .extend, .rename, .write],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            self?.refreshState()
        }
        source.setCancelHandler {
            close(descriptor)
        }
        fileSource = source
        source.resume()
    }

    private func refreshState() {
        let state = RunStateStore.loadValidated(for: workstreamID)
        if state == nil {
            attachFileWatcherIfNeeded()
        }

        let nextPort = state?.selectedPort
        let nextStatus: PortStatus = state == nil ? .none : (state?.selectedPort != nil ? .running : .starting)
        DispatchQueue.main.async { [weak self] in
            self?.selectedPort = nextPort
            self?.status = nextStatus
        }
    }
}
