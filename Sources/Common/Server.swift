// Server.swift — the one wire between a Swift controller and the app it controls.
//
// Marko, 26.9.2026: "let's upgrade our controlling pages from actual HTML to Swift applications. For
// now, leave the experimental feature so it can be web or Swift, two ways to launch the controller app."
//
// THE SWIFT APP IS A SECOND FACE ON THE SAME SERVER, NOT A SECOND APP. The MIDI logic lives in
// the MIDI engine and already answers two questions over HTTP on 127.0.0.1:
//
//     GET  /state   everything the page draws, as JSON
//     POST /do      one verb, {"a": "power"} and so on; the answer is the new state
//
// The web page asks exactly these, and so does this. So the two can be open at once, always agree, and
// neither can do anything the other cannot. Nothing about MIDI is written twice.

import Foundation
import SwiftUI

typealias JSON = [String: Any]

extension Dictionary where Key == String, Value == Any {
    func str(_ k: String) -> String { (self[k] as? String) ?? (self[k].map { "\($0)" } ?? "") }
    func bool(_ k: String) -> Bool { (self[k] as? Bool) ?? false }
    func int(_ k: String) -> Int { (self[k] as? Int) ?? Int((self[k] as? Double) ?? 0) }
    func num(_ k: String) -> Double { (self[k] as? Double) ?? Double(int(k)) }
    func list(_ k: String) -> [JSON] { (self[k] as? [JSON]) ?? [] }
    func strings(_ k: String) -> [String] { (self[k] as? [String]) ?? [] }
    func obj(_ k: String) -> JSON? { self[k] as? JSON }
}

@MainActor
final class Server: ObservableObject {
    /// the name the app's port is claimed under in ~/.config/mantra-ports.json, and its star key
    let key: String
    let usualPort: Int
    @Published private(set) var state: JSON = [:]
    @Published private(set) var up = false
    @Published private(set) var starting = false
    /// THE ACTIVITY LEDS: row id -> "fire" (green) or "heard" (amber), from GET /lit (1.10.2026)
    @Published private(set) var lit: [String: String] = [:]
    private var timer: Timer?
    private var litTimer: Timer?
    private var litAsking = false

    init(key: String, usualPort: Int) {
        self.key = key
        self.usualPort = usualPort
    }

    /// THE PORT IS ASKED, NOT ASSUMED. Every Mantra app claims its port through ~/.local/lib/mantra/
    /// ports.lua, which moves up a number when the usual one is taken and writes down where it went.
    var port: Int {
        let path = NSHomeDirectory() + "/.config/mantra-ports.json"
        if let d = FileManager.default.contents(atPath: path),
           let j = try? JSONSerialization.jsonObject(with: d) as? JSON,
           let me = j[key] as? JSON, let p = me["port"] as? Int { return p }
        return usualPort
    }
    var base: String { "http://127.0.0.1:\(port)" }
    var webURL: URL { URL(string: base)! }

    func begin() {
        refresh()
        // A LOOK TWICE A SECOND, as the page does: the log, the heard line and LEARN all change from
        // the controller's side, not from this window, so the window has to go and ask.
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        // AND THE ROWS' LIGHTS TWELVE TIMES A SECOND: a click of a knob lasts a third of a second, and
        // the half-second look above would miss most of them. /lit is a few bytes.
        litTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshLit() }
        }
    }

    func refreshLit() {
        guard up, !litAsking else { return }
        litAsking = true
        var r = URLRequest(url: URL(string: base + "/lit")!)
        r.timeoutInterval = 1
        URLSession.shared.dataTask(with: r) { data, _, _ in
            let j = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? JSON }
            let l = (j?["lit"] as? [String: String]) ?? [:]
            Task { @MainActor in
                self.litAsking = false
                if l != self.lit { self.lit = l }
            }
        }.resume()
    }

    func refresh() {
        var r = URLRequest(url: URL(string: base + "/state")!)
        r.timeoutInterval = 1.5
        URLSession.shared.dataTask(with: r) { data, _, _ in
            let j = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? JSON }
            Task { @MainActor in
                if let j { self.state = j; self.up = true; self.starting = false } else { self.up = false }
            }
        }.resume()
    }

    /// One verb, and the answer is drawn at once rather than at the next look.
    func verb(_ body: JSON) {
        var r = URLRequest(url: URL(string: base + "/do")!)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try? JSONSerialization.data(withJSONObject: body)
        r.timeoutInterval = 3
        URLSession.shared.dataTask(with: r) { data, _, _ in
            let j = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? JSON }
            Task { @MainActor in if let j { self.state = j; self.up = true } }
        }.resume()
    }

    /// Any other GET the app answers (MIDI to MK's /catalogue), decoded once.
    func fetch(_ path: String, _ done: @escaping @MainActor (Any?) -> Void) {
        URLSession.shared.dataTask(with: URL(string: base + path)!) { data, _, _ in
            let v = data.flatMap { try? JSONSerialization.jsonObject(with: $0) }
            Task { @MainActor in done(v) }
        }.resume()
    }

    /// WHEN THE APP IS OFF, THE WINDOW CAN SWITCH IT ON. Since 13.11.2026 there is no Hammerspoon to ask: both engines
    /// are the Swift app MIDI Tools (Mantra), opened in the background (`open -g`). Nothing starts by itself - a button he presses.
    func startInStar() {
        starting = true
        let c = NSWorkspace.OpenConfiguration(); c.activates = false
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/MIDI Tools (Mantra).app"), configuration: c) { _, _ in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in self?.starting = false }
    }

    func openWeb() { NSWorkspace.shared.open(webURL) }
}
