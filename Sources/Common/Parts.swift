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
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 5)
                .fill(on ? Ink.amber : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(on ? Ink.amber : Ink.slateHi, lineWidth: 1.5))
                .overlay(Text(on ? "\u{2713}" : "").font(.system(size: 12, weight: .bold)).foregroundColor(.black))
                .frame(width: 22, height: 22).opacity(dead ? 0.25 : 1)
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
    let sub: String
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 20, weight: .bold, design: .monospaced))
                    .tracking(2).foregroundColor(Ink.sand)
                Text(sub).font(Ink.mono).foregroundColor(Ink.dim)
            }
            Spacer()
            Pill(title: "WEB", look: .ghost) { s.openWeb() }.help("the same controls as a web page")
            if s.up { Power(on: s.state.bool("on")) { s.verb(["a": "power"]) } }
        }
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
    let sub: String
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Header(s: s, title: title, sub: sub)
                if s.up { content } else { Down(s: s, name: name) }
            }.padding(20)
        }
        .background(Ink.ground)
        .preferredColorScheme(.dark)
        .onAppear { s.begin() }
    }
}
