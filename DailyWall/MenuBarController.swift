import SwiftUI
import Combine

@MainActor
class MenuBarController: NSObject, ObservableObject {
    enum ImageSource: String, CaseIterable {
        case bing = "Bing"
        case picsum = "Picsum (Random 4K)"
    }

    @Published var autoRefreshEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoRefreshEnabled, forKey: "autoRefreshEnabled")
            updateMenuBar()
            if autoRefreshEnabled {
                scheduleRefresh()
            } else {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
        }
    }
    
    @Published var refreshTime: String {
        didSet {
            UserDefaults.standard.set(refreshTime, forKey: "refreshTime")
            updateMenuBar()
            if autoRefreshEnabled {
                scheduleRefresh()
            }
        }
    }
    
    @Published var lastUpdateTime: Date? {
        didSet {
            if let date = lastUpdateTime {
                UserDefaults.standard.set(date, forKey: "lastUpdateTime")
            }
        }
    }
    
    @Published var imageSource: ImageSource {
        didSet {
            UserDefaults.standard.set(imageSource.rawValue, forKey: "imageSource")
            updateMenuBar()
        }
    }
    
    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?
    
    override init() {
        // Initialize properties BEFORE super.init()
        self.autoRefreshEnabled = UserDefaults.standard.bool(forKey: "autoRefreshEnabled")
        self.refreshTime = UserDefaults.standard.string(forKey: "refreshTime") ?? "08:00"
        self.lastUpdateTime = UserDefaults.standard.object(forKey: "lastUpdateTime") as? Date
        
        if let saved = UserDefaults.standard.string(forKey: "imageSource"), let src = ImageSource(rawValue: saved) {
            self.imageSource = src
        } else {
            self.imageSource = .bing
        }
        
        super.init()
        print("MenuBarController init called")
        
        DispatchQueue.main.async {
            self.setupMenuBar()
            if self.autoRefreshEnabled {
                self.scheduleRefresh()
            }
        }
    }
    
    private func setupMenuBar() {
        print("Setting up menu bar...")
        
        // Create status item
        let newStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem = newStatusItem
        
        print("Status item created")
        
        // Get button
        guard let button = newStatusItem.button else {
            print("ERROR: Could not get button from status item")
            return
        }
        
        print("Button obtained successfully")
        
        // Set image
        button.image = NSImage(named: "MenuBarIcon")
        button.image?.isTemplate = true
        print("Image set")
        
        updateMenuBar()
    }
    
    private func updateMenuBar() {
        guard let statusItem = self.statusItem else { return }
        
        let menu = NSMenu()
        
        // Set Wallpaper Now
        let setWallpaperItem = NSMenuItem(title: "Set Wallpaper Now", action: #selector(setWallpaper), keyEquivalent: "w")
        setWallpaperItem.target = self
        menu.addItem(setWallpaperItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Auto Refresh Toggle
        let autoRefreshTitle = autoRefreshEnabled ? "✓ Auto Refresh" : "Auto Refresh"
        let autoRefreshItem = NSMenuItem(title: autoRefreshTitle, action: #selector(toggleAutoRefresh), keyEquivalent: "")
        autoRefreshItem.target = self
        menu.addItem(autoRefreshItem)
        
        // Refresh Time Submenu
        let refreshTimeMenu = NSMenu()
        let times = ["06:00", "07:00", "08:00", "09:00", "10:00", "12:00", "18:00", "21:00"]
        for time in times {
            let timeItem = NSMenuItem(title: time, action: #selector(setRefreshTime(_:)), keyEquivalent: "")
            timeItem.target = self
            timeItem.state = (time == refreshTime) ? .on : .off
            refreshTimeMenu.addItem(timeItem)
        }
        
        let refreshTimeItem = NSMenuItem(title: "Refresh Time", action: nil, keyEquivalent: "")
        refreshTimeItem.submenu = refreshTimeMenu
        menu.addItem(refreshTimeItem)
        
        // Image Source Submenu
        let sourceMenu = NSMenu()
        for source in ImageSource.allCases {
            let item = NSMenuItem(title: source.rawValue, action: #selector(setImageSource(_:)), keyEquivalent: "")
            item.target = self
            item.state = (source == imageSource) ? .on : .off
            item.representedObject = source.rawValue
            sourceMenu.addItem(item)
        }
        let sourceItem = NSMenuItem(title: "Image Source", action: nil, keyEquivalent: "")
        sourceItem.submenu = sourceMenu
        menu.addItem(sourceItem)
        
        // Removed Unsplash API key menu item and its separator
        
        // Separator before Last Update Time (ensure only one)
        menu.addItem(NSMenuItem.separator())
        
        // Last Update Time
        let lastUpdateTitle: String
        if let lastUpdate = lastUpdateTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            lastUpdateTitle = "Last Update: \(formatter.string(from: lastUpdate))"
        } else {
            lastUpdateTitle = "Last Update: Never"
        }
        let lastUpdateItem = NSMenuItem(title: lastUpdateTitle, action: nil, keyEquivalent: "")
        lastUpdateItem.isEnabled = false
        menu.addItem(lastUpdateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        print("Menu updated")
    }
    
    @objc private func toggleAutoRefresh() {
        autoRefreshEnabled.toggle()
    }
    
    @objc private func setRefreshTime(_ sender: NSMenuItem) {
        refreshTime = sender.title
    }
    
    @objc private func setImageSource(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let src = ImageSource(rawValue: raw) {
            imageSource = src
        }
    }
    
    private func scheduleRefresh() {
        // Cancel existing timer
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        // Parse refresh time
        let components = refreshTime.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return }
        
        let targetHour = components[0]
        let targetMinute = components[1]
        
        // Calculate next refresh time
        let calendar = Calendar.current
        var nextRefresh = calendar.date(bySettingHour: targetHour, minute: targetMinute, second: 0, of: Date())!
        
        // If the time has passed today, schedule for tomorrow
        if nextRefresh < Date() {
            nextRefresh = calendar.date(byAdding: .day, value: 1, to: nextRefresh)!
        }
        
        let timeInterval = nextRefresh.timeIntervalSinceNow
        print("Next refresh scheduled in \(timeInterval) seconds at \(nextRefresh)")
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            print("Auto-refresh triggered")
            self?.setWallpaper()
            // Reschedule for the next day
            self?.scheduleRefresh()
        }
    }
    
    @objc private func setWallpaper() {
        Task {
            do {
                let imageURL: URL?
                switch self.imageSource {
                case .bing:
                    imageURL = try await self.fetchBingWallpaperURL()
                case .picsum:
                    imageURL = try await self.fetchPicsumWallpaperURL()
                }
                guard let imageURL else { return }
                let localPath = try await downloadImage(from: imageURL)
                try setDesktopWallpaper(to: localPath)
                self.lastUpdateTime = Date()
                print("Wallpaper set successfully")
            } catch {
                print("Error setting wallpaper: \(error)")
            }
        }
    }
    
    private func fetchBingWallpaperURL() async throws -> URL? {
        let url = URL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let images = json?["images"] as? [[String: Any]],
            let image = images.first,
            let urlPath = image["url"] as? String
        else { return nil }
        let fullURL = URL(string: "https://www.bing.com\(urlPath)")
        print("Fetched image URL: \(fullURL?.absoluteString ?? "nil")")
        return fullURL
    }
    
    private func fetchPicsumWallpaperURL() async throws -> URL? {
        // Lorem Picsum provides random images without API keys.
        // Use a large size to approximate 4K (e.g., 3840x2160). The service will return a random image at that size.
        // We can also use /id/{id}/{w}/{h} but for random, /3840/2160 is sufficient.
        if let url = URL(string: "https://picsum.photos/3840/2160") {
            print("Using Picsum random 4K URL: \(url)")
            return url
        }
        return nil
    }
    
    private func downloadImage(from url: URL) async throws -> String {
        print("Downloading image from: \(url.absoluteString)")
        let (data, _) = try await URLSession.shared.data(from: url)
        let fileManager = FileManager.default
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("dailywall_wallpaper.jpg")
        
        try? fileManager.removeItem(at: fileURL)
        
        try data.write(to: fileURL)
        print("Image downloaded to: \(fileURL.path)")
        return fileURL.path
    }
    
    private func setDesktopWallpaper(to path: String) throws {
        print("Setting desktop wallpaper to: \(path)")
        let url = URL(fileURLWithPath: path)
        
        let screens = NSScreen.screens
        
        for screen in screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
                print("Wallpaper set for screen: \(screen)")
            } catch {
                print("Error setting wallpaper for screen: \(error)")
                throw error
            }
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
