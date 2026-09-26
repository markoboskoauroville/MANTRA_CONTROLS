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
