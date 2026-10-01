// MackieApp.swift — MIDI to MK Control, as a Mac window instead of a web page.
//
// Every control here is a verb the page already sends to mackie.lua (MANTRA_MACKIE): power, detect,
// unlock, out, back, add, tick, tickall, delete, undo, redo, learn, try, set, blob, blobhome, blobhold, clear. The MK command list
// is the app's own /catalogue, so a command added to mcu.lua appears here without this file changing.

import SwiftUI

let VERSION = "v4"

@main
struct MackieApp: App {
    @StateObject private var s = Server(key: "mackie", usualPort: 8855)
    @StateObject private var cat = Catalogue()
    var body: some Scene {
        WindowGroup("MIDI to MK Control") {
            Controls(s: s, name: "MIDI to MK Control", title: "MIDI TO MK CONTROL",
                     version: VERSION) {
                DeviceBand(s: s)
                ToLiveBand(s: s)
                BlobBand(s: s)
                MackieTable(s: s, cat: cat)
                TraceBand(s: s)
            }
            .frame(minWidth: 1040, minHeight: 640)
            .onAppear { cat.load(from: s) }
        }
        .windowStyle(.hiddenTitleBar)
    }
}

/// The MK commands, grouped as mcu.lua groups them, asked once when the window opens.
@MainActor
final class Catalogue: ObservableObject {
    @Published var groups: [(group: String, items: [(id: String, label: String)])] = []
    func load(from s: Server) {
        s.fetch("/catalogue") { v in
            guard let arr = v as? [JSON] else {
                // the app may still be starting: ask again shortly, rather than drawing an empty list forever
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.load(from: s) }
                return
            }
            self.groups = arr.map { g in (g.str("group"), g.list("items").map { ($0.str("id"), $0.str("label")) }) }
        }
    }
    func label(_ id: String) -> String {
        for g in groups { if let i = g.items.first(where: { $0.id == id }) { return i.label } }
        return id.isEmpty ? "pick a command" : id
    }
}

struct ToLiveBand: View {
    @ObservedObject var s: Server
    var body: some View {
        let st = s.state
        Band(title: "TO LIVE \u{2014} WHAT GOES OUT") {
            HStack(spacing: 10) {
                Text("Mackie goes to").font(Ink.mono).foregroundColor(Ink.dim)
                Choice(options: [("", "nothing")] + st.list("outs").map { ($0.str("name"), $0.str("label")) },
                       chosen: st.str("out"), width: 200) { s.verb(["a": "out", "name": $0]) }
                Text("Live's lights come back on").font(Ink.mono).foregroundColor(Ink.dim)
                Choice(options: [("", "not listening")] + st.list("backs").map { ($0.str("name"), $0.str("label")) },
                       chosen: st.str("back"), width: 200) { s.verb(["a": "back", "name": $0]) }
            }
            Text(st.str("sentLine")).font(Ink.mono).foregroundColor(Ink.sand)
            Text(st.str("backLine")).font(Ink.mono).foregroundColor(Ink.dim)
        }
    }
}

struct BlobBand: View {
    @ObservedObject var s: Server
    var body: some View {
        let st = s.state
        Band(title: "THE COMMAND BLOB \u{2014} THE TOAST AT THE TOP OF LIVE") {
            HStack(spacing: 10) {
                Pill(title: st.bool("blob") ? "ON" : "OFF", look: st.bool("blob") ? .lit : .ghost, width: 60) { s.verb(["a": "blob"]) }
                Pill(title: "PUT IT BACK AT THE TOP", look: .ghost) { s.verb(["a": "blobhome"]) }
                Text("It stays for").font(Ink.mono).foregroundColor(Ink.dim)
                Field(value: String(format: "%.1f", st.num("blobHold")), width: 56) { s.verb(["a": "blobhold", "seconds": Double($0) ?? 1.4]) }
                Text("seconds.").font(Ink.mono).foregroundColor(Ink.dim)
            }
            Text("the last one: " + st.str("blobLine")).font(Ink.mono).foregroundColor(Ink.sand)
        }
    }
}

struct MackieTable: View {
    @ObservedObject var s: Server
    @ObservedObject var cat: Catalogue
    static let w: [CGFloat] = [150, 70, 250, 130, 50, 34, 34, 130, 50, 30]   // the master's columns: Key Stroke copies them
    var body: some View {
        Band(title: "THE TABLE") {
            KeepBar(s: s)
            HStack(spacing: 8) {
                ForEach(Array(["FILTER", "VALUE", "MK COMMAND", "HOW", "INVERT", "ON", "LED", "LEARN", "TRY"].enumerated()), id: \.offset) { i, h in
                    Text(h).font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(1).foregroundColor(Ink.dim).frame(width: MackieTable.w[i], alignment: .leading)
                }
                SelectAll(s: s).frame(width: MackieTable.w[9])
            }
            let rows = s.state.list("rows")
            if rows.isEmpty {
                Text("No rows yet. Press + A ROW, then LEARN and turn the knob, then pick the MK command.")
                    .font(Ink.mono).foregroundColor(Ink.dim)
            }
            ForEach(rows.indices, id: \.self) { i in MackieRow(s: s, cat: cat, r: rows[i]) }
            Pill(title: "+ A ROW") { s.verb(["a": "add"]) }
        }
    }
}

struct MackieRow: View {
    @ObservedObject var s: Server
    @ObservedObject var cat: Catalogue
    let r: JSON
    var body: some View {
        let id = r.int("id")
        let learning = s.state.int("learn") == id
        let w = MackieTable.w
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                FilterCell(kind: r.str("from"), number: r.str("number"), lit: learning,
                           pickKind: { s.verb(["a": "set", "id": id, "from": $0]) },
                           setNumber: { s.verb(["a": "set", "id": id, "number": $0]) })
                    .frame(width: w[0], alignment: .leading)
                Field(value: r.str("valueText"), width: w[1], disabled: r.bool("sweep")) { s.verb(["a": "set", "id": id, "value": $0]) }
                Menu {
                    ForEach(cat.groups, id: \.group) { g in
                        Section(g.group) {
                            ForEach(g.items, id: \.id) { it in Button(it.label) { s.verb(["a": "set", "id": id, "command": it.id]) } }
                        }
                    }
                } label: {
                    Text(cat.label(r.str("command"))).font(Ink.mono).foregroundColor(Ink.sand).lineLimit(1)
                }
                .menuStyle(.borderlessButton).menuIndicator(.visible)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .frame(width: w[2], alignment: .leading).background(Ink.slate).cornerRadius(7)
                Choice(options: r.list("hows").map { ($0.str("id"), $0.str("label")) }, chosen: r.str("how"), width: w[3]) {
                    s.verb(["a": "set", "id": id, "how": $0])
                }
                Tick(on: r.bool("invert"), dead: !r.bool("relative")) { s.verb(["a": "set", "id": id, "invert": !r.bool("invert")]) }
                    .frame(width: w[4]).help(r.bool("relative") ? "the knob turns the other way" : "this command has no direction to turn round")
                Tick(on: r.bool("on")) { s.verb(["a": "set", "id": id, "on": !r.bool("on")]) }.frame(width: w[5])
                LedTick(s: s, r: r).frame(width: w[6])
                Pill(title: learnWords(learning, r.str("from")), look: learning ? .lit : .ghost, width: w[7]) { s.verb(["a": "learn", "id": id]) }
                Pill(title: "TRY", look: .ghost, width: w[8]) { s.verb(["a": "try", "id": id]) }.help("send this command once, now")
                SelectTick(s: s, r: r).frame(width: w[9])
            }
            if r.bool("clash") {
                Text("another row answers the same message \u{2014} both are sent").font(Ink.mono).foregroundColor(Ink.red)
            }
            Text(r.str("says")).font(Ink.mono).foregroundColor(Ink.dim).fixedSize(horizontal: false, vertical: true)
            LedLine(r: r)
        }
    }
}
