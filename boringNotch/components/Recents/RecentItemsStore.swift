//
//  RecentItemsStore.swift
//  Tracks the most recently changed files and folders in the user's main folders.
//

import AppKit
import Foundation

struct RecentItem: Identifiable, Equatable {
    let url: URL
    let date: Date
    let isDirectory: Bool
    var id: URL { url }
}

@MainActor
final class RecentItemsStore: ObservableObject {
    static let shared = RecentItemsStore()

    static let limit = 5
    private static let folderNames = ["Downloads", "Desktop", "Documents"]

    @Published private(set) var items: [RecentItem] = []

    private var watchers: [DispatchSourceFileSystemObject] = []
    private var refreshTask: Task<Void, Never>?

    private init() {
        startWatching()
        refresh()
    }

    func refresh() {
        refreshTask?.cancel()
        let roots = Self.roots
        refreshTask = Task { [weak self] in
            let found = await Task.detached(priority: .utility) { Self.scan(roots) }.value
            guard !Task.isCancelled else { return }
            self?.items = found
        }
    }

    private static var roots: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return folderNames.map { home.appendingPathComponent($0, isDirectory: true) }
    }

    private nonisolated static func scan(_ roots: [URL]) -> [RecentItem] {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .creationDateKey, .isDirectoryKey]
        var all: [RecentItem] = []
        for root in roots {
            guard let entries = try? FileManager.default.contentsOfDirectory(
                at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
            ) else { continue }
            for url in entries where url.pathExtension != "crdownload" && url.pathExtension != "download" {
                guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
                let date = [values.contentModificationDate, values.creationDate].compactMap { $0 }.max() ?? .distantPast
                all.append(RecentItem(url: url, date: date, isDirectory: values.isDirectory ?? false))
            }
        }
        return Array(all.sorted { $0.date > $1.date }.prefix(limit))
    }

    private func startWatching() {
        for root in Self.roots {
            let fd = open(root.path, O_EVTONLY)
            guard fd >= 0 else { continue }
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd, eventMask: [.write, .rename, .delete], queue: .main)
            source.setEventHandler { [weak self] in
                MainActor.assumeIsolated { self?.refresh() }
            }
            source.setCancelHandler { close(fd) }
            source.resume()
            watchers.append(source)
        }
    }
}
