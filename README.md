<img src="icon.svg" width="80" height="80" alt="Gastown icon">

![version](https://img.shields.io/badge/version-v1.1.0-blue) [![tests](https://github.com/nulljosh/gastown/actions/workflows/test.yml/badge.svg)](https://github.com/nulljosh/gastown/actions/workflows/test.yml) ![license](https://img.shields.io/badge/license-Apache%202.0-green)

Raise the Steam Clock.

Gastown (formerly NYC Survive) is a small colony game set in rainy Vancouver. You send a crew of survivors to work, build machines that run on their own, and raise the Gastown Steam Clock. Think Pikmin's crew and Factorio's machines, cut down to four buildings and one goal. You decide what everyone does.

**[gastown.jaybulb.com](https://gastown.jaybulb.com)** · **[Play in the browser](https://gastown.jaybulb.com/app/)** · **[App Store](https://apps.apple.com/app/id6782618198)**

<a href="https://apps.apple.com/app/id6782618198"><img src="https://tools.applemarketingtools.com/api/badges/download-on-the-app-store/black/en-us" alt="Download on the App Store" height="40"></a>

<img src="screenshots/gastown-2.jpg" width="600" alt="Gastown in the browser: a crew selected beside a shelter and a generator, rain over the map">

<img src="screenshots/gastown-1.jpg" width="600" alt="Gastown on Mac: a shelter, two generators and two drills, the crew at work">

## Features

- **Send the crew.** Click a survivor, or drag a box around several. Click a resource and they work it until you say otherwise. Click the ground to move them. Nobody works on their own.
- **Vancouver.** Burrard Inlet and False Creek, the seawall, SkyTrain stations, and rain.
- **Three resources.** Food, materials and power.
- **Four buildings.** Shelters add four beds. Generators make power. A drill beside a resource mines it and burns power, one drill per patch. The Steam Clock is the win.
- **The crew grows.** A free bed and 10 food bring a new survivor each day, up to 20.
- **Win.** Raise the Steam Clock: 8,000 materials and 1,000 power. About fifteen minutes if you build well.
- **Saves.** Autosave runs about once a minute. There are three save slots.
- **Apple.** iPhone, iPad and Mac. The Mac app has a resizable window and a full screen switch in Settings.
- **Web.** The same game runs in a browser at [/app](https://gastown.jaybulb.com/app/), with WebMCP tools for browser agents.
- **Apple Watch.** A quick reference for building costs.

## Run

```bash
xcodegen generate && open Gastown.xcodeproj
```

Needs Xcode 16 or later. The app targets iOS 17 and macOS 15.

Other ways in:

- **Web.** `cd web && python3 -m http.server 8000`, then open http://localhost:8000. Modules need a server, so `file://` will not work.
- **Headless playthrough.** `scripts/playthrough.sh 200` plays the bot to the win with no window.
- **Apple Watch.** `cd watchos && xcodegen generate && open GastownWatch.xcodeproj`

## Tests

```bash
node --test
xcodebuild test -project Gastown.xcodeproj -scheme Gastown -destination 'platform=macOS' -only-testing:SimTests
```

`node --test` runs the web tests, including `web/winnable.test.mjs`, which plays the game to a win. The Swift tests live in `Tests/SimTests.swift`.

## Docs

- [Controls](docs/CONTROLS.md): every key, click and tap.
- [Whitepaper](WHITEPAPER.md): how the game works and why.
- [Architecture](docs/ARCHITECTURE.md) and [Web API](docs/API.md).
- [Changelog](CHANGELOG.md).

Found a security problem? Email trommatic@icloud.com. See [SECURITY.md](SECURITY.md).

## Privacy

Gastown collects nothing. Saves stay on your device. There are no accounts, no analytics and no network calls. The full [privacy policy](https://gastown.jaybulb.com/app/privacy) is on the site.

## License

Apache License 2.0. See [LICENSE](LICENSE). Copyright 2026 Joshua Trommel.

The Gastown Sans typeface is Inter, renamed. It stays under the SIL Open Font License 1.1, see [Resources/Fonts/OFL.txt](Resources/Fonts/OFL.txt).
