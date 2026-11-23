//
//  NotchShelfCLI.swift
//  `notchshelf <path>...` — adds files to the shelf via the boringnotch://shelf URL scheme.
//

import AppKit
import Foundation

enum NotchShelfCLI {
    static var binDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/boringNotch/bin", isDirectory: true)
    }

    private static let script = """
    #!/bin/sh
    # notchshelf: put files on the boring.notch shelf
    [ $# -ge 1 ] || { echo "usage: notchshelf <path>..." >&2; exit 64; }
    status=0
    for p in "$@"; do
      if [ ! -e "$p" ]; then echo "notchshelf: no such file: $p" >&2; status=1; continue; fi
      abs="$(cd "$(dirname "$p")" && pwd -P)/$(basename "$p")"
      enc="$(printf %s "$abs" | /usr/bin/perl -pe 's/([^A-Za-z0-9_.~\\/-])/sprintf("%%%02X",ord($1))/ge')"
      /usr/bin/open -g "boringnotch://shelf?path=$enc" || status=1
    done
    exit $status
    """

    /// Writes the helper script; call at launch. For other terminals, symlink it into your PATH.
    static func installScript() {
        let fm = FileManager.default
        let file = binDirectory.appendingPathComponent("notchshelf")
        do {
            try fm.createDirectory(at: binDirectory, withIntermediateDirectories: true)
            try script.write(to: file, atomically: true, encoding: .utf8)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)
        } catch {
            NSLog("notchshelf install failed: \(error.localizedDescription)")
        }
    }

    /// Handles boringnotch://shelf?path=/abs/path
    @MainActor
    static func handle(_ url: URL) {
        guard url.scheme == "boringnotch", url.host == "shelf",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return }
        let items: [ShelfItem] = (comps.queryItems ?? [])
            .filter { $0.name == "path" }
            .compactMap { $0.value }
            .filter { $0.hasPrefix("/") }
            .compactMap { path in
                let fileURL = URL(fileURLWithPath: path)
                guard let bookmark = try? Bookmark(url: fileURL).data else { return nil }
                return ShelfItem(kind: .file(bookmark: bookmark))
            }
        ShelfStateViewModel.shared.add(items)
    }
}
