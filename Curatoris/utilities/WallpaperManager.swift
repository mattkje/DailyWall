import Foundation
import AppKit

// Make WallpaperManager public and its methods public so it is visible to the rest of the app
public final class WallpaperManager {
    public init() {}
    public static func shouldUseOsascript() -> Bool {
        return UserDefaults.standard.bool(forKey: "useOsascriptForWallpaper")
    }
    public func setWallpaperWithOsascript(to path: String) throws {
        let script = "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"\(path)\""
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw NSError(domain: "WallpaperManager", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "osascript failed to set wallpaper"])
        }
    }
    public func downloadImage(from url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("curatoris_\(UUID().uuidString).jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }
    public func setDesktopWallpaper(to path: String, fillMode: NSImageScaling = .scaleProportionallyUpOrDown) throws {
        if WallpaperManager.shouldUseOsascript() {
            try setWallpaperWithOsascript(to: path)
        } else {
            let url = URL(fileURLWithPath: path)
            let allowClipping = (fillMode == .scaleProportionallyUpOrDown)
            let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                .imageScaling:   fillMode.rawValue,
                .allowClipping:  allowClipping
            ]
            var allSucceeded = true
            for screen in NSScreen.screens {
                do {
                    try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: options)
                    let current = NSWorkspace.shared.desktopImageURL(for: screen)
                    if current?.path != path { allSucceeded = false }
                } catch {
                    allSucceeded = false
                }
            }
            if !allSucceeded {
                WallpaperManager.promptEnableOsascriptIfNeeded()
            }
        }
    }
    public static func isLikelyManagedMac() -> Bool {
        let managedPaths = [
            "/Library/Managed Preferences/",
            "/Library/Profiles/",
            "/Library/Preferences/com.apple.ManagedClient.plist"
        ]
        let fileManager = FileManager.default
        return managedPaths.contains { fileManager.fileExists(atPath: $0) }
    }
    public static func promptEnableOsascriptIfNeeded() {
        guard !shouldUseOsascript(), isLikelyManagedMac() else { return }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Managed Mac Detected"
            alert.informativeText = "Your Mac appears to be managed or restricted. Would you like to enable the AppleScript (osascript) workaround for setting the wallpaper?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Enable Workaround")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                UserDefaults.standard.set(true, forKey: "useOsascriptForWallpaper")
            }
        }
    }
}
