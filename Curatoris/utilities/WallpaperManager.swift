import Foundation
import AppKit

final class WallpaperManager {
    func downloadImage(from url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("curatoris_\(UUID().uuidString).jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    func setDesktopWallpaper(to path: String, fillMode: NSImageScaling = .scaleProportionallyUpOrDown) throws {
        let url = URL(fileURLWithPath: path)
        // .allowClipping: true + scaleProportionallyUpOrDown = "Fill" (scale to fill, crop edges)
        // Without allowClipping it becomes "Fit" (letterbox).
        let allowClipping = (fillMode == .scaleProportionallyUpOrDown)
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling:   fillMode.rawValue,
            .allowClipping:  allowClipping
        ]
        for screen in NSScreen.screens {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: options)
        }
    }
}
