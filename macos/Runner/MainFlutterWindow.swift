import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // Room for the register table plus the interpretation panel.
    self.setContentSize(NSSize(width: 1360, height: 860))
    self.contentMinSize = NSSize(width: 720, height: 560)
    self.title = "Modbus Explorer"
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
