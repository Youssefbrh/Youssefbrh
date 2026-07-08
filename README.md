# NotchNova ✨

A free, open notch companion for your MacBook — everything NotchNook does,
plus a pet, live system stats, sneak alerts and ambient aurora vibes.
No subscription, no license key, nothing leaves your Mac.

## Features

| | |
|---|---|
| 🗂 **File shelf** | Drag files onto the notch to stash them, drag them back out into any app. Survives restarts. |
| 🎵 **Now Playing** | Album art, track info, play/pause/skip for Spotify & Apple Music, with a beat-style visualizer. |
| 📊 **Live stats** | CPU, RAM, temperature, network throughput and battery — ring gauges + CPU sparkline. |
| 🔊 **Notch HUD** | Volume and brightness changes appear as sleek wings around the notch. |
| 🔔 **Sneak alerts** | Battery low, CPU hot, charger plugged, timer done — Dynamic-Island-style slide-outs. |
| 📋 **Clipboard history** | Last 30 things you copied, one click to re-copy. |
| 🍅 **Pomodoro** | Focus/break timer with a live progress line on the closed notch. |
| 🪞 **Mirror** | Quick camera check right in the notch. |
| 🐱 **Notch pet** | A little creature that naps, strolls, dances to your music, gets startled by file drops, and loves being petted. |
| 🌌 **Aurora vibes** | Ambient gradient glow under the island — slow drift or music-reactive. |

Works best on a notched MacBook (2021+). On non-notched displays it renders a
virtual notch at the top-center so every feature still works.

## Build & run (macOS 14 Sonoma or newer)

1. Clone the repo and open **`NotchNova.xcodeproj`** in Xcode (15.3 or newer).
2. Select the **NotchNova** scheme, press **⌘R**.
   - Signing is preconfigured as *Sign to Run Locally* — no Apple developer
     account or team needed.
3. The app appears as a ✨ icon in the menu bar (no Dock icon). Hover the
   notch to open it.

### Permissions it may ask for

- **Automation (Spotify / Music)** — first time it reads what's playing.
  Only needed if the system-wide media API is unavailable (macOS 15.4+).
- **Camera** — only when you open the Mirror tool. Nothing is recorded.

Both are optional; deny them and everything else keeps working.

## Using it

- **Hover** the notch → it springs open. Move away → it closes.
- **Drag a file** toward the notch → the shelf opens; drop to stash.
  Drag items out of the shelf into Finder, Mail, Slack, anywhere.
  Double-click a shelf item to reveal it in Finder.
- **Tabs**: Home (media + stats) · Shelf · Tools (clipboard / pomodoro /
  mirror) · Pet.
- **Click the pet** to pet it. It dances when music plays. You can rename it
  in Settings.
- **Settings** live behind the ✨ menu bar icon — toggle any feature,
  change the aurora style, enable launch-at-login.

## Troubleshooting

**"NotchNova can't be opened because it is from an unidentified developer"**
You launched a copied .app outside Xcode. Right-click → Open → Open, or just
run from Xcode.

**Build fails with a signing error**
Target → *Signing & Capabilities* → set *Signing Certificate* to
**Sign to Run Locally** (and Team to *None*). No account required.

**Build fails with "requires macOS 14.0"**
Your macOS is older than Sonoma. Update macOS, or lower
`MACOSX_DEPLOYMENT_TARGET` in `tools/genproj.py`, re-run
`python3 tools/genproj.py`, and fix any API availability errors Xcode points
out.

**No album art / track info**
On macOS 15.4+ Apple locked down the system media API. NotchNova falls back
to talking to Spotify/Music directly — approve the Automation permission
prompt (System Settings → Privacy & Security → Automation).

**No temperature gauge**
Some Apple Silicon models don't expose SMC temperature keys to apps; the
gauge hides itself when nothing is readable. Everything else is unaffected.

**The notch window disappeared after unplugging a monitor**
It re-anchors automatically on display changes; if it ever gets lost, click
the ✨ menu icon → *Open Notch*.

## Project layout

```
NotchNova.xcodeproj/    generated — don't edit by hand
NotchNova/
  App/                  entry point, app delegate, menu bar item, Info.plist
  Core/                 notch panel, geometry, state machine, theme, prefs
  Views/                island container, notch shape, closed/expanded UI,
                        visualizer, aurora glow
  Features/             one folder per feature (Shelf, Media, Stats, HUD,
                        Alerts, Clipboard, Pomodoro, Mirror, Pet)
  Settings/             settings window
tools/genproj.py        regenerates the .xcodeproj after adding/removing files:
                        python3 tools/genproj.py
```

### Adding a Swift file

Drop it anywhere under `NotchNova/`, run `python3 tools/genproj.py`, reopen
Xcode. The generator derives stable IDs from paths, so diffs stay minimal.
