// MidiKeysApp.swift — MIDI to Key Stroke, as a Mac window instead of a web page.
//
// Every control here is a verb the page already sends to midikeys.lua (MIDI_TO_KEYSTROKE): power,
// detect, unlock, add, tick, tickall, delete, undo, redo, learn, capture, set, clear. Since 1.10.2026 the
// table copies MIDI to MK Control, the master: FILTER (CC or NOTE, and the number), VALUE, KEY, what it is,
// ON, LEARN, and the tick; UNDO, REDO and DELETE above it.

import SwiftUI

let VERSION = "v5"

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
            .frame(minWidth: 1040, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct TableBand: View {
    @ObservedObject var s: Server
    // the columns, the same widths in the head and in every row
    static let w: [CGFloat] = [150, 70, 250, 170, 34, 60, 130, 30]   // FILTER, VALUE, LEARN and the tick as wide as the master's
    var body: some View {
        let st = s.state
        Band(title: "THE TABLE") {
            KeepBar(s: s)
            HStack(spacing: 8) {
                ForEach(Array(["FILTER", "VALUE", "KEY", "WHAT IT IS", "ON", "LED", "LEARN"].enumerated()), id: \.offset) { i, h in
                    Text(h).font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(1).foregroundColor(Ink.dim).frame(width: TableBand.w[i], alignment: .leading)
                }
                SelectAll(s: s).frame(width: TableBand.w[7])
            }
            let rows = st.list("rows")
            if rows.isEmpty {
                Text("No rows yet. Press + A ROW, then LEARN to catch the knob or the key, then the KEY cell and the key you want.")
                    .font(Ink.mono).foregroundColor(Ink.dim)
            }
            ForEach(rows.indices, id: \.self) { i in RowView(s: s, r: rows[i]) }
            HStack {
                Pill(title: "+ A ROW") { s.verb(["a": "add"]) }
                Text("FILTER is CC (a knob) or NOTE (a key or pad): LEARN takes only that kind. For a note, VALUE is the velocity. Press the KEY cell, then the key.")
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
                FilterCell(kind: r.str("type"), number: r.str("cc"), lit: learning,
                           pickKind: { s.verb(["a": "set", "id": id, "type": $0]) },
                           setNumber: { s.verb(["a": "set", "id": id, "number": $0]) })
                    .frame(width: w[0], alignment: .leading)
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
                HStack(spacing: 6) { LedTick(s: s, r: r); LedSwatch(s: s, r: r) }.frame(width: w[5])
                Pill(title: learnWords(learning, r.str("type")), look: learning ? .lit : .ghost, width: w[6]) {
                    s.verb(["a": "learn", "id": id])
                }
                SelectTick(s: s, r: r).frame(width: w[7])
            }
            if r.bool("clash") {
                Text("another row answers the same MIDI and value \u{2014} both keys are pressed").font(Ink.mono).foregroundColor(Ink.red)
            }
            if !r.str("hint").isEmpty && r.str("hint") != "<null>" {
                Text(r.str("hint")).font(Ink.mono).foregroundColor(Ink.dim)
            }
            LedLine(r: r)
        }
    }
}
