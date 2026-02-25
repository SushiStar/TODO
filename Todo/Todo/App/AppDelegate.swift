import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSPanel?
    let viewModel = TaskViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 500),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.fullScreenNone]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let x = frame.maxX - 320 - 20
            let y = frame.maxY - 500 - 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let content = ContentView().environment(viewModel)
        panel.contentView = NSHostingView(rootView: content)
        panel.makeKeyAndOrderFront(nil)

        self.window = panel

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    @objc func activeSpaceDidChange() {
        guard let panel = window, !panel.isOnActiveSpace else { return }
        panel.orderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
