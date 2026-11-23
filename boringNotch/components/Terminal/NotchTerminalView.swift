//
//  NotchTerminalView.swift
//  Embedded terminal tab (SwiftTerm). One shell session lives for the app's lifetime.
//

import AppKit
import SwiftTerm
import SwiftUI

@MainActor
final class NotchTerminalSession {
    static let shared = NotchTerminalSession()

    let view: LocalProcessTerminalView

    private init() {
        let v = LocalProcessTerminalView(frame: .zero)
        v.nativeBackgroundColor = .clear
        v.nativeForegroundColor = .white
        v.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        view = v

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
        let bin = NotchShelfCLI.binDirectory.path
        let path = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env.append("PATH=\(bin):\(path)")
        v.startProcess(
            executable: shell,
            args: ["-l"],
            environment: env,
            execName: "-" + (shell as NSString).lastPathComponent,
            currentDirectory: NSHomeDirectory()
        )
    }

    /// Types shell-quoted paths at the prompt without pressing return.
    func type(paths: [String]) {
        let quoted = paths.map { "'" + $0.replacingOccurrences(of: "'", with: "'\\''") + "'" }
        guard !quoted.isEmpty else { return }
        view.send(txt: quoted.joined(separator: " ") + " ")
    }
}

struct NotchTerminalView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let container = TerminalContainer()
        let term = NotchTerminalSession.shared.view
        term.removeFromSuperview()
        term.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(term)
        NSLayoutConstraint.activate([
            term.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            term.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            term.topAnchor.constraint(equalTo: container.topAnchor),
            term.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        BoringNotchSkyLightWindow.allowsKey = false
    }
}

/// Grabs keyboard focus when clicked: the notch panel normally refuses key status.
private final class TerminalContainer: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        BoringNotchSkyLightWindow.allowsKey = true
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(NotchTerminalSession.shared.view)
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(NotchTerminalSession.shared.view)
        super.mouseDown(with: event)
    }
}
