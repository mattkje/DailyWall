//
//  GalleryWindowController.swift
//  Curatoris
//
//  Created by Matti Kjellstadli on 25/04/2026.
//


import AppKit
import SwiftUI

final class GalleryWindowController: NSWindowController {
    static let shared = GalleryWindowController()

    private init() {
        let hosting = NSHostingController(rootView: GalleryView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "Gallery"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 900, height: 600))
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
