// MidiKeysApp.swift — MIDI to Key Stroke, as a Mac window instead of a web page.
//
// Every control here is a verb the page already sends to midikeys.lua (MIDI_TO_KEYSTROKE): power,
// detect, unlock, add, delete, learn, capture, set, clear. The table reads as the page's: MIDI (CC 13
// for a knob, N 60 for a note), VALUE, KEY, what it is, ON, LEARN.

import SwiftUI

let VERSION = "v2"

@main
struct MidiKeysApp: App {
    @StateObject private var s = Server(key: "midikeys", usualPort: 8853)
    var body: some Scene {
        WindowGroup("MIDI to Key Stroke") {
            Controls(s: s, name: "MIDI to Key Stroke", title: "MIDI TO KEY STROKE",
                   version: VERSION) {
                DeviceBand(s: s)
                TableBand(s: s)
                TraceBand(s: s)
            }
            .frame(minWidth: 820, minHeight: 560)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct TableBand: View {
    @ObservedObject var s: Server
    // the columns, the same widths in the head and in every row
    static let w: [CGFloat] = [86, 70, 190, 170, 34, 150, 30]
    var body: some View {
        let st = s.state
        Band(title: "THE TABLE") {
            HStack(spacing: 8) {
                ForEach(Array(["MIDI", "VALUE", "KEY", "WHAT IT IS", "ON", "LEARN", ""].enumerated()), id: \.offset) { i, h in
                    Text(h).font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(1).foregroundColor(Ink.dim).frame(width: TableBand.w[i], alignment: .leading)
                }
            }
            let rows = st.list("rows")
            if rows.isEmpty {
                Text("No rows yet. Press + A ROW, then LEARN to catch the knob or the key, then the KEY cell and the key you want.")
                    .font(Ink.mono).foregroundColor(Ink.dim)
            }
            ForEach(rows.indices, id: \.self) { i in RowView(s: s, r: rows[i]) }
            HStack {
                Pill(title: "+ A ROW") { s.verb(["a": "add"]) }
                Text("MIDI is CC 13 for a knob or N 60 for a note; for a note, VALUE is the velocity. Type them, or take them from the controller with LEARN.")
                    .font(Ink.mono).foregroundColor(Ink.dim).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct RowView: View {
    @ObservedObject var s: Server
    let r: JSON
    var body: some View {
        let id = r.int("id")
        let st = s.state
        let learning = st.int("learn") == id
        let capturing = st.int("capture") == id
        let sweep = r.bool("sweep")
        let w = TableBand.w
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Field(value: r.str("midi"), width: w[0], lit: learning) { s.verb(["a": "set", "id": id, "midi": $0]) }
                Field(value: r.str("valueText"), width: w[1], disabled: sweep) { s.verb(["a": "set", "id": id, "value": $0]) }
                HStack(spacing: 4) {
                    Pill(title: capturing ? "press a key\u{2026}" : (sweep ? "\u{2014}" : (r.str("target").isEmpty ? "press to set" : r.str("target"))),
                         look: capturing ? .lit : .plain, width: r.str("key").isEmpty || sweep ? w[2] : w[2] - 34) {
                        if !sweep { s.verb(["a": "capture", "id": id]) }
                    }.disabled(sweep)
                    if !r.str("key").isEmpty && !sweep {
                        Pill(title: "\u{00D7}", look: .ghost, width: 30) { s.verb(["a": "set", "id": id, "key": ""]) }
                            .help("forget this key")
                    }
                }.frame(width: w[2], alignment: .leading)
                HStack(spacing: 4) {
                    Pill(title: "KEY", look: r.str("kind") == "key" ? .lit : .ghost) { s.verb(["a": "set", "id": id, "kind": "key"]) }
                    Pill(title: "VOLUME", look: r.str("kind") == "volume" ? .lit : .ghost) { s.verb(["a": "set", "id": id, "kind": "volume"]) }
                }.frame(width: w[3], alignment: .leading)
                Tick(on: r.bool("on")) { s.verb(["a": "set", "id": id, "on": !r.bool("on")]) }.frame(width: w[4])
                Pill(title: learning ? "turn or press\u{2026}" : "LEARN", look: learning ? .lit : .ghost, width: w[5]) {
                    s.verb(["a": "learn", "id": id])
                }
                Pill(title: "\u{2717}", look: .ghost, width: w[6]) { s.verb(["a": "delete", "id": id]) }.help("remove this row")
            }
            if r.bool("clash") {
                Text("another row answers the same MIDI and value \u{2014} both keys are pressed").font(Ink.mono).foregroundColor(Ink.red)
            }
            if !r.str("hint").isEmpty && r.str("hint") != "<null>" {
                Text(r.str("hint")).font(Ink.mono).foregroundColor(Ink.dim)
            }
        }
    }
}
