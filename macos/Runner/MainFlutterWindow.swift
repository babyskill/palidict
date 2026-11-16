import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var customTitle: String = "Từ điển Pāḷi - Việt - giacngo.org"

  override var title: String {
    get {
      return customTitle
    }
    set {
      super.title = customTitle
    }
  }

  func setAppTitle(_ newTitle: String) {
    customTitle = newTitle
    super.title = newTitle
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "org.giacngo.palidict/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "setWindowTitle" {
        if let args = call.arguments as? [String: Any], let title = args["title"] as? String {
          self?.setAppTitle(title)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Title is required", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()

    self.setAppTitle(customTitle)
  }
}
