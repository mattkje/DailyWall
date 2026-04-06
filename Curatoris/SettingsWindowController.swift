import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let hosting = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "Curatoris Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 760, height: 520))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func showWindow() {
        guard let window = self.window else { return }
        if !window.isVisible { window.center() }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        ensureEditMenu()
    }

    private func ensureEditMenu() {
        if NSApp.mainMenu == nil {
            NSApp.mainMenu = NSMenu()
        }
        guard let mainMenu = NSApp.mainMenu else { return }

        // Remove any stale Edit menu first
        if let existing = mainMenu.item(withTitle: "Edit") {
            mainMenu.removeItem(existing)
        }

        let editMenuItem = NSMenuItem()
        editMenuItem.title = "Edit"
        let editMenu = NSMenu(title: "Edit")

        let items: [(String, Selector, String)] = [
            ("Undo",            #selector(UndoManager.undo),          "z"),
            ("Redo",            #selector(UndoManager.redo),          "Z"),
            ("-", NSSelectorFromString(""), ""),
            ("Cut",             #selector(NSText.cut(_:)),            "x"),
            ("Copy",            #selector(NSText.copy(_:)),           "c"),
            ("Paste",           #selector(NSText.paste(_:)),          "v"),
            ("Select All",      #selector(NSText.selectAll(_:)),      "a"),
            ("-", NSSelectorFromString(""), ""),
            ("Delete",          #selector(NSText.delete(_:)),         ""),
        ]

        for (title, action, key) in items {
            if title == "-" {
                editMenu.addItem(.separator())
            } else {
                editMenu.addItem(NSMenuItem(title: title, action: action, keyEquivalent: key))
            }
        }

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
    }
}
