# DailyWall

A lightweight macOS menu bar application that automatically updates your desktop wallpaper with beautiful images daily, sourced from Bing, Picsum, or Pexels.

## Features
- Fetch wallpapers from multiple sources: **Bing**, **Picsum**, and **Pexels**
- Automatic daily refresh at your chosen time
- Hourly refresh option
- Lightweight menu bar application (no dock icon)
- Multi-monitor support — applies wallpaper across all connected displays
- Persistent settings saved between launches

## Installation

Download the latest release from the [Releases](../../releases) page and drag **DailyWall.app** to your Applications folder.

Alternatively, clone the repository and build the project in Xcode.

## Configuration

### Pexels API Key (optional)

To use the **Pexels** image source, you need a free API key from [pexels.com/api](https://www.pexels.com/api/).

Set the key via an Xcode scheme environment variable or in `Info.plist`:

- **Xcode scheme**: Add `PEXELS_API_KEY` as an environment variable in the scheme's *Run* settings.
- **Info.plist**: Set the value for the `PexelsAPIKey` key.

If no key is configured, the Pexels source is silently skipped.

## Usage

### First Launch
1. Launch the app from Xcode or your Applications folder
2. You'll see a photo icon in your menu bar on the right side
3. Click it to open the menu

### Menu Options

**Set Wallpaper Now** — Immediately fetch and set a new wallpaper from the selected source

**Auto Refresh** — Toggle automatic wallpaper updates (checkmark indicates enabled)

**Refresh Time** — Choose what time the wallpaper updates:
- Any hour from 00:00 to 23:00
- **Every Hour** — refresh at the start of every hour instead of a fixed daily time

**Image Source** — Choose where wallpapers are downloaded from:
- **Bing (Only 1080p)** — Today's Bing daily image (up to 1080p)
- **Picsum** — Random high-resolution image from Lorem Picsum
- **Pexels** — Random landscape photo from Pexels (requires API key)

**Last Update** — View when your wallpaper was last changed

**About** — View app version and visit the developer's website

**Quit** — Close the application

## How It Works

1. **Fetches image URL** — Contacts the selected source's API to retrieve a wallpaper URL
2. **Downloads image** — Saves the full-resolution wallpaper to a temporary folder
3. **Sets wallpaper** — Applies the image to all connected displays via `NSWorkspace`
4. **Schedules next update** — If auto-refresh is enabled, schedules the next update at the configured time

## Technical Details

### Architecture
- Built with SwiftUI and AppKit
- Runs as an accessory app (menu bar only, no dock icon)
- Uses `NSStatusBar` for menu bar integration
- Leverages `NSWorkspace` for wallpaper setting

### Data Storage
Settings are persisted using `UserDefaults`:
- `autoRefreshEnabled` — Auto-refresh toggle state
- `refreshTime` — Selected refresh time (HH:MM format, default: `08:00`)
- `everyHourEnabled` — Whether to refresh every hour instead of at a fixed daily time
- `imageSource` — Selected image source (raw string value)
- `lastUpdateTime` — Timestamp of last wallpaper update

### Network
| Source | Endpoint |
|--------|----------|
| Bing | `https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1` |
| Picsum | `https://picsum.photos/3840/2160` |
| Pexels | `https://api.pexels.com/v1/search` |

Requires internet connectivity. The Pexels endpoint requires an `Authorization` header containing your API key.

### Permissions
The app requires the following macOS permissions:
- **Network**: To fetch wallpapers from the selected image source
- **System Events**: To update your desktop wallpaper (configured via entitlements)

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## Support

For issues, feature requests, or questions, please open an issue on GitHub.
