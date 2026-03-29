import SwiftUI
import Combine

@MainActor
class MenuBarController: NSObject, ObservableObject {
    enum ImageSource: String, CaseIterable {
        case bing = "Bing (Only 1080p)"
        case picsum = "Picsum"
        case pexels = "Pexels"
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

    @Published var everyHourEnabled: Bool {
        didSet {
            UserDefaults.standard.set(everyHourEnabled, forKey: "everyHourEnabled")
            updateMenuBar()
            if autoRefreshEnabled {
                scheduleRefresh()
            }
        }
    }
    
    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?
    
    override init() {
        // Initialize properties BEFORE super.init()
        self.autoRefreshEnabled = UserDefaults.standard.bool(forKey: "autoRefreshEnabled")
        self.refreshTime = UserDefaults.standard.string(forKey: "refreshTime") ?? "08:00"
        self.lastUpdateTime = UserDefaults.standard.object(forKey: "lastUpdateTime") as? Date
        self.everyHourEnabled = UserDefaults.standard.bool(forKey: "everyHourEnabled")
        
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
        
    
        let autoRefreshTitle = autoRefreshEnabled ? "✓ Auto Refresh" : "Auto Refresh"
        let autoRefreshItem = NSMenuItem(title: autoRefreshTitle, action: #selector(toggleAutoRefresh), keyEquivalent: "")
        autoRefreshItem.target = self
        menu.addItem(autoRefreshItem)

        let refreshTimeMenu = NSMenu()

        let times = [
            "00:00","01:00","02:00","03:00","04:00","05:00","06:00","07:00","08:00","09:00","10:00","11:00",
            "12:00","13:00","14:00","15:00","16:00","17:00","18:00","19:00","20:00","21:00","22:00","23:00"
        ]
        for time in times {
            let timeItem = NSMenuItem(title: time, action: #selector(setRefreshTime(_:)), keyEquivalent: "")
            timeItem.target = self
            timeItem.state = (!everyHourEnabled && time == refreshTime) ? .on : .off
            refreshTimeMenu.addItem(timeItem)
        }

        refreshTimeMenu.addItem(NSMenuItem.separator())
        let everyHourTitle = everyHourEnabled ? "✓ Every Hour" : "Every Hour"
        let everyHourItem = NSMenuItem(title: everyHourTitle, action: #selector(toggleEveryHour), keyEquivalent: "")
        everyHourItem.target = self
        refreshTimeMenu.addItem(everyHourItem)

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
        
        menu.addItem(NSMenuItem.separator())
        
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
        
        // About
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
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
        everyHourEnabled = false
        refreshTime = sender.title
    }
    
    @objc private func toggleEveryHour() {
        everyHourEnabled.toggle()
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

        let calendar = Calendar.current
        let now = Date()

        if everyHourEnabled {
            // Schedule at the start of the next hour
            var comps = calendar.dateComponents([.year, .month, .day, .hour], from: now)
            comps.minute = 0
            comps.second = 0
            let startOfHour = calendar.date(from: comps) ?? now
            var next = startOfHour
            if next <= now { next = calendar.date(byAdding: .hour, value: 1, to: startOfHour) ?? now.addingTimeInterval(3600) }
            let interval = next.timeIntervalSinceNow
            print("Next hourly refresh in \(interval) seconds at \(next)")
            refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                print("Auto-refresh (hourly) triggered")
                Task { @MainActor in
                    self?.setWallpaper()
                    // Schedule the next hour
                    self?.scheduleRefresh()
                }
            }
            return
        }

        // Parse refresh time (specific daily time)
        let components = refreshTime.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return }
        let targetHour = components[0]
        let targetMinute = components[1]

        var nextRefresh = calendar.date(bySettingHour: targetHour, minute: targetMinute, second: 0, of: now) ?? now
        if nextRefresh < now {
            nextRefresh = calendar.date(byAdding: .day, value: 1, to: nextRefresh) ?? now.addingTimeInterval(24*3600)
        }
        let timeInterval = nextRefresh.timeIntervalSinceNow
        print("Next refresh scheduled in \(timeInterval) seconds at \(nextRefresh)")
        refreshTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            print("Auto-refresh triggered")
            Task { @MainActor in
                self?.setWallpaper()
                // Reschedule for the next day
                self?.scheduleRefresh()
            }
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
                case .pexels:
                    imageURL = try await self.fetchPexelsWallpaperURL()
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
    
    private func pexelsAPIKey() -> String? {
        // 1) Prefer env var set via Build Settings or Scheme Environment
        if let env = ProcessInfo.processInfo.environment["PEXELS_API_KEY"], !env.isEmpty {
            return env
        }
        // 2) Fallback to Info.plist if present
        if let plist = Bundle.main.object(forInfoDictionaryKey: "PexelsAPIKey") as? String, !plist.isEmpty {
            return plist
        }
        return nil
    }
    
    private func fetchPexelsWallpaperURL() async throws -> URL? {

        guard let apiKey = pexelsAPIKey(), !apiKey.isEmpty else {
            print("Pexels API key missing.")
            return nil
        }

        let queries = [
            "landscape nature",
            "mountains",
            "ocean",
            "forest",
            "minimal landscape",
            "abstract gradient",
            "night sky",
            "desert",
            "snow landscape"
        ]

        let query = queries.randomElement() ?? "landscape"

        var components = URLComponents(string: "https://api.pexels.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "40"),
            URLQueryItem(name: "orientation", value: "landscape"),
            URLQueryItem(name: "size", value: "large")
        ]

        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            print("Pexels API error: status \(http.statusCode)")
            return nil
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let photos = json["photos"] as? [[String: Any]]
        else {
            return nil
        }

        let filtered = photos.filter { photo in
            let peopleCount = photo["people"] as? Int ?? 0
            return peopleCount == 0
        }

        guard !filtered.isEmpty else {
            print("No suitable wallpapers found.")
            return nil
        }

        let photo = filtered.randomElement()!

        if let src = photo["src"] as? [String: Any] {
            if let originalString = src["original"] as? String,
               let originalURL = URL(string: originalString) {
                return originalURL
            }

            let fallbackKeys = ["large2x", "large", "landscape"]
            for key in fallbackKeys {
                if let str = src[key] as? String,
                   var comps = URLComponents(string: str) {
                    comps.queryItems = nil
                    return comps.url
                }
            }
        }

        return nil
    }
    
    private func downloadImage(from url: URL) async throws -> String {
        print("Downloading image from: \(url.absoluteString)")
        let (data, _) = try await URLSession.shared.data(from: url)

        let tempDir = FileManager.default.temporaryDirectory
        let uniqueName = "dailywall_\(UUID().uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(uniqueName)

        try data.write(to: fileURL, options: .atomic)
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
    
    @objc private func showAbout() {
        let alert = NSAlert()
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        
        alert.messageText = "DailyWall"
        
        alert.informativeText = """
        A lightweight macOS menu bar application that automatically updates your desktop wallpaper with beautiful Bing images daily.

        Version \(version) (\(build))
        Created by Matti Kjellstadli

        mattikjellstadli.com
        """
        
        if let icon = NSImage(named: "AppIcon") ?? NSImage(named: "MenuBarIcon") {
            alert.icon = icon
        }
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Visit Website")
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn,
           let url = URL(string: "https://mattikjellstadli.com/product/25") {
            NSWorkspace.shared.open(url)
        }
    }
}

