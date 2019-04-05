import Cocoa
import Kanna
import Yaml

// Connect Travis CI
// TODO add menu with exit button
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let file = ".stocks"
    let defaultYaml = """
AAPL:
  market : nasdaq

FAG:
  market : nasdaqomxnordic
  id     : SSE903
"""

    var stocks: Yaml?
    var position: Int = -2

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        var yaml = defaultYaml

        let fileUrl = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(file)
        do {
            yaml = try String(contentsOf: fileUrl, encoding: .utf8)
        }
        catch {/* error handling here */}

        stocks = try! Yaml.load(yaml)
        update(self)
        statusItem.button!.action = #selector(update(_:))
    }

    @objc func update(_ sender: Any?) {
        if let button = statusItem.button {
            button.imagePosition = NSControl.ImagePosition.imageLeft
            let img = NSImage(named: NSImage.Name("icons8-increase-filled-128"))!
            img.size = NSSize(width: 22, height: 22)
            button.image = img

            let count = stocks!.dictionary!.count
            position = (position + 2)
            if position >= count {
                position = 0
            }

            let ss = stocks!.dictionary!.dropFirst(position).prefix(2)
            var text = ""

            for (stock, params) in ss {
                let stock: String = stock.string!
                let market: String = params["market"].string!
                let id: String? = params["id"].string

                if !text.isEmpty {
                    text += "\n"
                }

                text += getData(market, stock, id)
            }

            if count > 1 && ss.count == 1 {
                text += "\n"
            }

            button.attributedTitle = NSAttributedString(
                string: text,
                attributes: [
                    NSAttributedStringKey.font: NSFont(name: "Helvetica", size: count > 1 ? 8 : 10)!
                ]
            )
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
                print(today)
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
        return "\(symbol) \(value)"
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
        // Insert code here to tear down your application
    }
}

