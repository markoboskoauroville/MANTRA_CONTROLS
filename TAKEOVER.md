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
