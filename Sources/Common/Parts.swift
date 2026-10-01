// Parts.swift — the look, and the pieces both controllers are built from.
//
// THE COLOURS ARE THE PAGES' OWN, read out of MIDI_TO_KEYSTROKE/page.lua's stylesheet, so the web face
// and the Swift face of one app look like the same app: ground, surface, slate, amber, sand.

import SwiftUI

enum Ink {
    static let ground  = Color(hex: 0x0B0D10)
    static let surface = Color(hex: 0x141A21)
    static let slate   = Color(hex: 0x23303D)
    static let slateHi = Color(hex: 0x2C3B4B)
    static let amber   = Color(hex: 0xF59E0B)
    static let sand    = Color(hex: 0xF2DDB4)
    static let dim     = Color(hex: 0xF2DDB4).opacity(0.45)
    static let red     = Color(hex: 0xEF4444)
    static let green   = Color(hex: 0x34D399)
    static let mono    = Font.system(size: 12, design: .monospaced)
    static let monoB   = Font.system(size: 12, weight: .semibold, design: .monospaced)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// A band of the page: a quiet uppercase title and what belongs under it.
struct Band<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(2).foregroundColor(Ink.dim)
            content
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Ink.surface).cornerRadius(12)
    }
}

/// The page's buttons: slate by default, amber when lit, an outline when quiet.
struct Pill: View {
    enum Look { case plain, lit, ghost, danger }
    let title: String
    var look: Look = .plain
    var width: CGFloat? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(Ink.monoB).lineLimit(1)
                .foregroundColor(look == .lit ? .black : (look == .danger ? Ink.red : Ink.sand))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .frame(width: width)
                .background(look == .lit ? Ink.amber : (look == .plain ? Ink.slate : Color.clear))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(look == .ghost ? Ink.slate : (look == .danger ? Ink.red.opacity(0.6) : Color.clear), lineWidth: 1))
                .cornerRadius(8)
        }.buttonStyle(.plain)
    }
}

/// The square tick the pages draw for ON and INVERT.
struct Tick: View {
    let on: Bool
    var dead = false
    var tint: Color = Ink.amber
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 5)
                .fill(on ? tint : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(on ? tint : Ink.slateHi, lineWidth: 1.5))
                .overlay(Text(on ? "\u{2713}" : "").font(.system(size: 12, weight: .bold)).foregroundColor(.black))
                .frame(width: 22, height: 22).opacity(dead ? 0.25 : 1)
                // AN EMPTY TICK IS CLEAR, AND SWIFTUI DOES NOT HIT-TEST CLEAR: only its thin border took a
                // click, so a row could not be ticked for DELETE (Marko, 1.10.2026). The whole square is the button.
                .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(dead)
    }
}

/// THE BIG SWITCH at the top right: everything stops when it says OFF, and the table is kept.
struct Power: View {
    let on: Bool
    let action: () -> Void
    var body: some View {
        Pill(title: on ? "ON" : "OFF", look: on ? .lit : .danger, width: 70, action: action)
            .help(on ? "sending: press to stop everything, the table is kept" : "stopped: press to send again")
    }
}

/// A box that is typed into and sent when he presses Return or leaves it - and that the twice-a-second
/// look does not overwrite while he is typing in it.
struct Field: View {
    let value: String
    var width: CGFloat = 70
    var disabled = false
    var lit = false
    let commit: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool
    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain).font(Ink.mono).foregroundColor(Ink.sand)
            .padding(.horizontal, 8).padding(.vertical, 6)
            .frame(width: width)
            .background(Ink.ground).cornerRadius(7)
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(lit || focused ? Ink.amber : Ink.slate, lineWidth: 1))
            .focused($focused)
            .disabled(disabled).opacity(disabled ? 0.4 : 1)
            .onAppear { text = value }
            .onChange(of: value) { _, v in if !focused { text = v } }
            .onChange(of: focused) { _, f in if !f && text != value { commit(text) } }
            .onSubmit { if text != value { commit(text) } }
    }
}

/// A menu that looks like the rest: the chosen label in a slate box.
struct Choice: View {
    let options: [(id: String, label: String)]
    let chosen: String
    var width: CGFloat = 170
    let pick: (String) -> Void
    var body: some View {
        Menu {
            ForEach(options, id: \.id) { o in Button(o.label) { pick(o.id) } }
        } label: {
            Text(options.first { $0.id == chosen }?.label ?? (chosen.isEmpty ? "\u{2014}" : chosen))
                .font(Ink.mono).foregroundColor(Ink.sand).lineLimit(1)
        }
        .menuStyle(.borderlessButton).menuIndicator(.visible)
        .padding(.horizontal, 8).padding(.vertical, 5)
        .frame(width: width, alignment: .leading)
        .background(Ink.slate).cornerRadius(7)
    }
}

/// THE DEVICE BAND, the same in both apps: DETECT locks the controller that speaks first.
struct DeviceBand: View {
    @ObservedObject var s: Server
    var body: some View {
        let st = s.state
        Band(title: "THE DEVICE \u{2014} WHAT COMES IN") {
            HStack(spacing: 10) {
                Pill(title: st.bool("detect") ? "TURN OR PRESS SOMETHING\u{2026}" : "DETECT DEVICE",
                     look: st.bool("detect") ? .lit : .plain) { s.verb(["a": "detect"]) }
                Pill(title: "UNLOCK", look: .ghost) { s.verb(["a": "unlock"]) }
                Text(st.str("device").isEmpty ? "no device locked" : "locked to " + st.str("deviceLabel"))
                    .font(Ink.mono).foregroundColor(st.str("device").isEmpty ? Ink.dim : Ink.sand)
            }
            if let h = st.obj("heard") {
                HStack(spacing: 8) {
                    Circle().fill(h.bool("mine") ? Ink.green : Ink.dim).frame(width: 8, height: 8)
                    Text(h.str("line")).font(Ink.mono).foregroundColor(Ink.sand)
                    Text(h.str("ago")).font(Ink.mono).foregroundColor(Ink.dim)
                }
            } else {
                Text("nothing heard yet").font(Ink.mono).foregroundColor(Ink.dim)
            }
            Text(st.str("why")).font(Ink.mono).foregroundColor(st.bool("bad") ? Ink.red : Ink.dim)
        }
    }
}

/// WHAT IT DID: the log, newest first, as the page shows it.
struct TraceBand: View {
    @ObservedObject var s: Server
    var body: some View {
        Band(title: "WHAT IT DID") {
            let lines = s.state.strings("trace")
            VStack(alignment: .leading, spacing: 3) {
                if lines.isEmpty { Text("nothing yet").font(Ink.mono).foregroundColor(Ink.dim) }
                ForEach(Array(lines.prefix(40).enumerated()), id: \.offset) { _, l in
                    Text(l).font(Ink.mono).foregroundColor(Ink.sand).textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10).background(Ink.ground).cornerRadius(8)
            Pill(title: "CLEAR", look: .ghost) { s.verb(["a": "clear"]) }
        }
    }
}

/// The top of the window: the name, what it is, WEB for the other face, and the big switch.
/// When the app is off, this is also where it is switched on.
struct Header: View {
    @ObservedObject var s: Server
    let title: String
    let version: String
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(title).font(.system(size: 20, weight: .bold, design: .monospaced))
                        .tracking(2).foregroundColor(Ink.sand)
                    Text(version).font(Ink.mono).foregroundColor(Ink.dim)
                }
                MidiMonitor(s: s)
            }
            Spacer()
            Pill(title: "WEB", look: .ghost) { s.openWeb() }.help("the same controls as a web page")
            if s.up { Power(on: s.state.bool("on")) { s.verb(["a": "power"]) } }
        }
    }
}

/// THE INCOMING MIDI MONITOR, where the line under the title used to be. Marko, 1.10.2026: "Instead of
/// that text, I want to see incoming MIDI messages ... it scans every MIDI port, and whatever it
/// receives, it shows there"; "the same monitor everywhere." The ring and the wording live once, in
/// ~/.local/lib/mantra/midiwatch.lua, and arrive here as /state's `incoming`; the web page draws the
/// same four lines. Always four lines high, so nothing under it moves when MIDI starts or stops.
struct MidiMonitor: View {
    @ObservedObject var s: Server
    var body: some View {
        let items = s.state.list("incoming")
        VStack(alignment: .leading, spacing: 2) {
            if !s.up {
                line("not running, so not listening", port: "", count: 1, ago: "", fresh: false)
            } else if items.isEmpty {
                let ports = s.state.strings("listening")
                line("no MIDI yet \u{2014} listening on " + (ports.isEmpty ? "no port at all" : ports.joined(separator: ", ")),
                     port: "", count: 1, ago: "", fresh: false)
            } else {
                ForEach(Array(items.prefix(4).enumerated()), id: \.offset) { i, m in
                    line(m.str("text"), port: m.str("port"), count: m.int("count"), ago: m.str("ago"),
                         fresh: i == 0 && m.str("ago") == "just now")
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 4 * 17, alignment: .top)
        .help("every MIDI message arriving on every port, newest first")
    }
    @ViewBuilder func line(_ text: String, port: String, count: Int, ago: String, fresh: Bool) -> some View {
        HStack(spacing: 0) {
            Circle().fill(fresh ? Ink.amber : Color.clear).frame(width: 7, height: 7).padding(.trailing, 7)
            if !port.isEmpty { Text(port).frame(width: 150, alignment: .leading) }
            Text(text).frame(minWidth: port.isEmpty ? 0 : 170, alignment: .leading)
            if count > 1 { Text("\u{00D7}\(count)").foregroundColor(Ink.amber).padding(.trailing, 12) }
            Text(ago)
        }
        .font(Ink.mono).foregroundColor(fresh ? Ink.sand : Ink.dim).lineLimit(1).frame(height: 15)
    }
}

/// THE APP IS OFF: said plainly, with the switch that turns it on, instead of an empty window.
struct Down: View {
    @ObservedObject var s: Server
    let name: String
    var body: some View {
        Band(title: "NOT RUNNING") {
            Text("\(name) is not running, so there is nothing to control. It lives in the star menu; this switches it on the same way the star's tick does.")
                .font(Ink.mono).foregroundColor(Ink.sand).fixedSize(horizontal: false, vertical: true)
            Pill(title: s.starting ? "STARTING\u{2026}" : "START \(name.uppercased())", look: .lit) { s.startInStar() }
                .disabled(s.starting)
        }
    }
}

/// The window's frame: the dark ground, the header, and the bands in a scroll.
struct Controls<Content: View>: View {
    @ObservedObject var s: Server
    let name: String          // as it is written: "MIDI to Key Stroke", never title-cased into "Midi"
    let title: String
    let version: String
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Header(s: s, title: title, version: version)
                if s.up { content } else { Down(s: s, name: name) }
            }.padding(20)
        }
        .background(Ink.ground)
        .preferredColorScheme(.dark)
        .onAppear { s.begin() }
    }
}

// ---------------------------------------------------------------- the table's own parts, the same in both apps
// Marko, 1.10.2026: "the last column when there are x's should be select buttons, and then there should be
// action buttons to delete and undo and redo ... both apps should be the same ... MIDI to MKControl is the
// master." The history and the ticks live in ~/.local/lib/mantra/tablekeep.lua and arrive as /state's `keep`;
// the web pages draw the same bar from the same state.

/// UNDO, REDO, what the last change was, and DELETE for the ticked rows. Always there, dimmed when idle.
struct KeepBar: View {
    @ObservedObject var s: Server
    var body: some View {
        let k = s.state.obj("keep")
        let n = (k?["ticked"] as? [Any])?.count ?? 0
        let canUndo = k?.bool("canUndo") ?? false, canRedo = k?.bool("canRedo") ?? false
        HStack(spacing: 10) {
            Pill(title: "UNDO", look: .plain) { s.verb(["a": "undo"]) }
                .opacity(canUndo ? 1 : 0.4).disabled(!canUndo)
                .keyboardShortcut("z", modifiers: .command)
                .help(canUndo ? "undo: " + (k?.str("undoWhat") ?? "") + "   (\u{2318}Z)" : "nothing to undo")
            Pill(title: "REDO", look: .plain) { s.verb(["a": "redo"]) }
                .opacity(canRedo ? 1 : 0.4).disabled(!canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .help(canRedo ? "redo: " + (k?.str("redoWhat") ?? "") + "   (\u{21E7}\u{2318}Z)" : "nothing to redo")
            Text(canUndo ? "last change: " + (k?.str("undoWhat") ?? "") : "")
                .font(.system(size: 11, design: .monospaced)).foregroundColor(Ink.dim).lineLimit(1)
            Spacer()
            Pill(title: n == 0 ? "DELETE" : "DELETE \(n) " + (n == 1 ? "ROW" : "ROWS"), look: n == 0 ? .ghost : .danger) {
                s.verb(["a": "delete"])
            }
            .opacity(n == 0 ? 0.4 : 1).disabled(n == 0)
            .help(n == 0 ? "tick rows in the last column first" : "delete the ticked rows (UNDO brings them back)")
        }
    }
}

/// The tick in a row's last column: tick, then DELETE above the table.
struct SelectTick: View {
    @ObservedObject var s: Server
    let r: JSON
    var body: some View {
        Tick(on: r.bool("ticked"), tint: Ink.sand) { s.verb(["a": "tick", "id": r.int("id")]) }
            .help("tick, then DELETE above the table")
    }
}

/// The tick in the last column's head: every row, or none.
struct SelectAll: View {
    @ObservedObject var s: Server
    var body: some View {
        Tick(on: s.state.obj("keep")?.bool("allTicked") ?? false, tint: Ink.sand) { s.verb(["a": "tickall"]) }
            .help("tick every row, or none")
    }
}

/// FILTER: CC or NOTE, and the number. LEARN takes only the kind chosen here, so a knob turned by accident
/// cannot be learned onto a row that waits for a note.
struct FilterCell: View {
    let kind: String          // "cc" or "note"
    let number: String
    var lit = false
    let pickKind: (String) -> Void
    let setNumber: (String) -> Void
    var body: some View {
        HStack(spacing: 4) {
            Choice(options: [("cc", "CC"), ("note", "NOTE")], chosen: kind, width: 72, pick: pickKind)
                .help("LEARN takes only this kind of message")
            Field(value: number, width: 70, lit: lit, commit: setNumber)
        }
    }
}

/// The LEARN button's words while it waits: what the filter lets in.
func learnWords(_ learning: Bool, _ kind: String) -> String {
    learning ? (kind == "note" ? "press a note\u{2026}" : "turn a knob\u{2026}") : "LEARN"
}

/// THE LED TICK: the E16 knob behind the row lights from here (e16led.lua). Drawn in the knob's own scene
/// colour; dead, with the reason in its help, when there is nothing to light.
struct LedTick: View {
    @ObservedObject var s: Server
    let r: JSON
    var body: some View {
        let a = r.obj("ledAbout")
        let can = a?.bool("can") ?? false
        let hex = UInt32((a?.str("colour") ?? "").replacingOccurrences(of: "#", with: ""), radix: 16)
        Tick(on: r.bool("led") && can, dead: !can, tint: hex.map { Color(hex: $0) } ?? Ink.amber) {
            s.verb(["a": "set", "id": r.int("id"), "led": !r.bool("led")])
        }
        .help(a?.str("says") ?? "")
    }
}

/// The line under a row whose LED is ticked: which knob, and what it will do.
struct LedLine: View {
    let r: JSON
    var body: some View {
        if r.bool("led"), let a = r.obj("ledAbout") {
            Text("LED: " + a.str("says")).font(Ink.mono).foregroundColor(Ink.dim).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// THE COLOUR SWATCH beside the LED tick: the knob's scene colour; a click opens the E16's own 10 x 10 palette,
/// and a pick is written into the scene file (e16colour.py). He sends the scene to the E16 from the OXI App.
struct LedSwatch: View {
    @ObservedObject var s: Server
    let r: JSON
    @State private var open = false
    var body: some View {
        let a = r.obj("ledAbout")
        let knob = a?.str("knob") ?? ""
        let has = !knob.isEmpty && knob != "<null>"
        let hex = UInt32((a?.str("colour") ?? "").replacingOccurrences(of: "#", with: ""), radix: 16)
        Button { if has { open = true } } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(has ? (hex.map { Color(hex: $0) } ?? Ink.slate) : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.25), lineWidth: 1))
                .frame(width: 16, height: 16).opacity(has ? 1 : 0.2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain).disabled(!has)
        .help(has ? "the colour of " + knob + ": click to change it in the scene" : (a?.str("says") ?? ""))
        .popover(isPresented: $open) {
            let pal = s.state.strings("ledPalette")
            let cur = a?.int("index") ?? -1
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 3), count: 10), spacing: 3) {
                ForEach(Array(pal.enumerated()), id: \.offset) { i, c in
                    Button {
                        open = false
                        s.verb(["a": "colour", "id": r.int("id"), "index": i])
                    } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: UInt32(c.replacingOccurrences(of: "#", with: ""), radix: 16) ?? 0))
                            .frame(width: 22, height: 22)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(i == cur ? Ink.sand : Color.clear, lineWidth: 2))
                    }.buttonStyle(.plain).help("colour \(i)")
                }
            }
            .padding(10).background(Ink.surface)
        }
    }
}

/// THE ACTIVITY LED in front of every row (1.10.2026): green while the row fires, amber while his hand
/// reaches it and nothing is sent; a knob glows a moment after each click, a note stays lit while it is down.
struct ActLed: View {
    @ObservedObject var s: Server
    let r: JSON
    var body: some View {
        let how = s.lit[String(r.int("id"))]
        let c: Color = how == "fire" ? Ink.green : (how == "heard" ? Ink.amber : Ink.slate)
        Circle().fill(c).frame(width: 10, height: 10)
            .shadow(color: how == nil ? .clear : c, radius: 4)
            .help("lights while your hand moves this row on the controller: green = it fired, amber = heard, nothing sent")
    }
}
