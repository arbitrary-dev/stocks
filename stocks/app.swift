import Cocoa
import Kanna
import Yaml
import RxSwift

// Connect Travis CI
// TODO add menu with exit button
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let updatePeriod: RxTimeInterval = 15 * 60 // 15 minutes

    let file = ".stocks"
    let defaultYaml = """
AAPL:
  market : nasdaq

FAG:
  market : nasdaqomxnordic
  id     : SSE903
"""

    var stocks: Yaml?
    var position: Int = 0

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    let subject = PublishSubject<Event>()
    var polling: Disposable?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        var yaml = defaultYaml

        let fileUrl = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(file)
        do {
            yaml = try String(contentsOf: fileUrl, encoding: .utf8)
        }
        catch {/* error handling here */}

        stocks = try! Yaml.load(yaml)

        if let button = statusItem.button {
            button.imagePosition = NSControl.ImagePosition.imageLeft
            let img = NSImage(named: NSImage.Name("icons8-increase-filled-128"))!
            img.size = NSSize(width: 22, height: 22)
            button.image = img
            button.action = #selector(onButtonPressed)
            // let longGesture = NSPressGestureRecognizer(...)
            // button.addGestureRecognizer(longGesture)
        }

        let updates: Observable<Event> =
            Observable<Int>.timer(0, period: updatePeriod, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                .map { _ in .update }

        polling = Observable.of(subject, updates)
            .merge()
            .subscribe {
                print($0.element ?? $0)
                switch $0.element {
                case .some(.update):
                    self.updateData()
                case .some(.next):
                    self.next()
                default:
                    ()
                }
            }
    }

    @objc func onButtonPressed(_ sender: Any?) {
        subject.onNext(.next)
    }

    private func next() {
        let count = stocks!.dictionary!.count
        position = (position + 2)
        if position >= count {
            position = 0
        }
        updateUi()
    }

    private func updateData() {
        let ss = stocks!.dictionary!

        updateUi(isLoading: true)

        for (stock, params) in ss {
            let stock = stock.string!
            let market = params["market"].string!
            let id = params["id"].string

            stocks![.string(stock)]["value"] = .string(getData(market, stock, id))
        }

        updateUi(isLoading: false)
    }

    private func updateUi(isLoading: Bool? = nil) {
        let ss = stocks!.dictionary!.dropFirst(position).prefix(2)
        var text = ""

        for (stock, params) in ss {
            let stock: String = stock.string!
            let value: String = params["value"].string ?? "…"

            if !text.isEmpty {
                text += "\n"
            }

            text += "\(stock) \(value)"
        }

        let count = stocks!.dictionary!.count

        // Trickery to make a lonely value take its place at the top.
        if count > 1 && ss.count == 1 {
            text += "\n"
        }

        DispatchQueue.main.async {
            var attrs = [NSAttributedStringKey: AnyObject]()
            attrs[NSAttributedStringKey.font] = NSFont(name: "Helvetica", size: count > 1 ? 8 : 10)!
            if let l = isLoading {
                attrs[NSAttributedStringKey.foregroundColor] = l ? NSColor.controlShadowColor : NSColor.controlTextColor
            }
            self.statusItem.button!.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        }
    }

    private func getData(_ market: String, _ symbol: String, _ id: String? = nil) -> String {
        var value: String = "n/a"
        switch market {
        case "nasdaqomxnordic":
            if let doc = try? HTML(url: URL(string: "https://www.nasdaqomxnordic.com/webproxy/DataFeedProxy.aspx?SubSystem=Prices&Instrument=\(id!)&Action=GetInstrument&inst.an=lp,hp")!, encoding: .utf8) {
                // TODO if Today is not available, then take current value
                if let low = Double(xp(doc, "//*/@lp")) {
                    if let high = Double(xp(doc, "//*/@hp")) {
                        value = String(format: "%.0f–%.0f", low, high)
                    }
                }
            }
        case "nasdaq":
            if let doc = try? HTML(url: URL(string: "https://nasdaq.com/symbol/\(symbol)")!, encoding: .utf8) {
                let today = xp(doc, "//div[b/text()[contains(., 'Today')]]/following-sibling::div").replacingOccurrences(of: ",", with: "")
                let arr = re("[0-9]+\\.?[0-9]*", today).map { Double($0)! }
                if arr.count != 2 {
                    break
                }
                let low = arr.min()!
                let high = arr.max()!
                value = String(format: "%.0f–%.0f", low, high)
            }
        default:
            break
        }
        return value
    }

    private func xp(_ doc: HTMLDocument, _ path: String) -> String {
        return doc.xpath(path).first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func re(_ regex: String, _ text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        polling!.dispose()
    }
}
