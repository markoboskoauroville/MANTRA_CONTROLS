# TAKEOVER — MANTRA_CONTROLS

**State, 26.9.2026:** v1 of both apps built and used against the live servers. Proven: the table and
bands draw from `/state`; a click in the window changes the server (DETECT on and off, read back over
HTTP) in both apps; with the app switched off the window shows NOT RUNNING and START switches it on;
the Launcher's APP opens the window, and with the app off it starts it first. His MIDI to Key Stroke
table (Port 1, 7 rows) survived every test.

**Not yet:** his own hands on it; the other ten star pages (App Store, Download Monitor, Installation
Logger, Ableton Assistant A1, Voice cloning, Find a file, Star Monitor, Spotlight, Voices, Sister app).

**Where things are:** the star's side is in MANTRA_STAR (`star.lua`: `isOnKey`, `openNativeKey`, `native`
in `STAR.list()`; `apps/*.lua`: `M.native`). The Launcher's APP button is in STAR_LAUNCHER `Panel.swift`.

## 13.11.2026: no Hammerspoon

> "Let me know why this Hammer Spoon is still running when I'm converting everything to Swift. If something is not converted, please create agents to convert anything that is still on Hammer Spoon to Swift right now." (Marko, 13.11.2026)

v8: the ON button of the two windows (`startInStar`) opens MIDI Tools (Mantra).app with `open -g` instead of asking Hammerspoon (`hs -c STAR.toggleKey`). Built by GitHub (.github/workflows/build.yml, both apps, release Latest). These windows are the old faces of the Lua engines; MIDI Tools (Mantra) replaces them.


## From the former README (13.11.2026)

# MANTRA_CONTROLS

**The star apps' control pages as Mac windows, in Swift.** One per app, beside the web page, never
instead of it.

Marko, 26.9.2026: *"let's upgrade our controlling pages from actual HTML to Swift applications. For
now, leave the experimental feature so it can be web or Swift, two ways to launch the controller app."*

| App | Controls | Its server | v |
|---|---|---|---|
| MIDI to Key Stroke.app | MIDI_TO_KEYSTROKE (`midikeys.lua`) | 127.0.0.1:8853 | 3 |
| MIDI to MK Control.app | MANTRA_MACKIE (`mackie.lua`) | 127.0.0.1:8855 | 3 |

## How it works

The MIDI logic lives in Hammerspoon and already serves two things over HTTP: `GET /state` (everything
the page draws, as JSON) and `POST /do` (one verb: `{"a": "power"}`, `{"a": "set", "id": 3, "midi": "N 60"}` …).
**The Swift window asks exactly the same two things the web page asks.** So both can be open at once,
they always agree, and neither can do anything the other cannot; nothing about MIDI is written twice.
The window looks again twice a second, as the page does.

- The port is read from `~/.config/mantra-ports.json` (the claim `ports.lua` writes), falling back to
  the usual one.
- When the app is off, the window says so and offers **START**, which ticks it on in the star (it asks
  `STAR.isOnKey` first, so START can never become a stop). Nothing starts by itself.
- **WEB** in the window's corner opens the page; the Launcher's **APP** beside WEB opens the window,
  starting the app first if it is off (`STAR.openNativeKey`). Both apps' own star submenus also have
  *Open the app (Swift)* and *Open the page (web)*.

## Building

```sh
sh build.sh              both apps, into apps/ (not in git)
sh build.sh midikeys     one
```

swiftc straight, no Xcode project, macOS 14 or later, Apple Silicon.

```
Sources/Common/Server.swift   the wire: /state, /do, the port, START
Sources/Common/Parts.swift    the look (the pages' own colours) and the shared bands
Sources/MidiKeys/             MIDI to Key Stroke
Sources/Mackie/               MIDI to MK Control
```

## Adding the next app

Every star app with a page answers `/state` and `/do` the same way. Read its `page.lua` for the
bands and verbs, write `Sources/<App>/<App>App.swift` from the shared parts, add a line to `build.sh`,
and give its star file `M.native = ".../apps/<Name>.app"` — the Launcher shows APP from then on.

## State at close, 13.11.2026

v8 (13.11.2026): the windows start MIDI Tools (Mantra) instead of asking Hammerspoon; GitHub workflow; public repo without README.
