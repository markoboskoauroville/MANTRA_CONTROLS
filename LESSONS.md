# LESSONS — MANTRA_CONTROLS

1. **A second face on the same server, not a second app.** The web page was already a thin client of
   `/state` and `/do`; the Swift window is another one. That is why the port had to be done in a day and
   why the two can never disagree.
2. **SwiftUI already has a type called `Window`.** Naming the shared frame `Window` compiled into a
   clash; it is `Controls`.
3. **Never title-case a product name.** `"MIDI TO KEY STROKE".capitalized` is "Midi To Key Stroke".
   The window is handed the name as it is written.
4. **START must ask before it toggles.** The star's switch is a toggle; pressed on an app that is
   already on, it stops it. `STAR.isOnKey` exists so the window can check first.
5. **`hs` reads stdin when it is not a terminal** (MIDI_TO_KEYSTROKE, same day): every `Process` that
   runs it gets `standardInput = FileHandle.nullDevice`.
6. **The line under the title is the incoming MIDI monitor** (v2, 1.10.2026): `MidiMonitor` in Parts.swift draws
   /state's `incoming`, always four lines high; the version sits beside the title. The ring and the words are in
   ~/.local/lib/mantra/midiwatch.lua, so the window and the page can never word a message differently.
7. **v3, 1.10.2026: MIDI to MK Control is the master.** `KeepBar`, `SelectTick`, `SelectAll`, `FilterCell` and
   `learnWords` in Parts.swift are the table's shared parts; Key Stroke copies MK's column widths. `ticked` in
   /state is a list of numbers, not of objects: `list()` reads it as empty, count it as `[Any]`.
