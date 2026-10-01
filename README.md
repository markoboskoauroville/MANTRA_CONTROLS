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

    sh build.sh              both apps, into apps/ (not in git)
    sh build.sh midikeys     one

swiftc straight, no Xcode project, macOS 14 or later, Apple Silicon.

    Sources/Common/Server.swift   the wire: /state, /do, the port, START
    Sources/Common/Parts.swift    the look (the pages' own colours) and the shared bands
    Sources/MidiKeys/             MIDI to Key Stroke
    Sources/Mackie/               MIDI to MK Control

## Adding the next app

Every star app with a page answers `/state` and `/do` the same way. Read its `page.lua` for the
bands and verbs, write `Sources/<App>/<App>App.swift` from the shared parts, add a line to `build.sh`,
and give its star file `M.native = ".../apps/<Name>.app"` — the Launcher shows APP from then on.
