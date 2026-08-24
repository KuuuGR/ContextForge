import Cocoa
import FlutterMacOS
import StoreKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Application-level method channel used by the Flutter App Review flow.
    // The native side presents Apple's SYSTEM review prompt via
    // `AppStore.requestReview(in:)`; it does not add any purchase/StoreKit
    // transaction code. Keep in sync with lib/services/app_review_service.dart.
    let channel = FlutterMethodChannel(
      name: "contextforge/review",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "requestReview":
        MainFlutterWindow.requestSystemReview(result: result)
      case "getVersion":
        result(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  /// Asks Apple to present the system review prompt (macOS 13.0+).
  ///
  /// Apple decides whether the prompt is actually shown and how often. We do
  /// not assume a rating/review was submitted, and we never read the user's
  /// rating. On older macOS versions this is a graceful no-op.
  private static func requestSystemReview(result: @escaping FlutterResult) {
    guard #available(macOS 13.0, *),
          let controller = NSApplication.shared.keyWindow?.contentViewController else {
      result(nil)
      return
    }
    Task { @MainActor in
      AppStore.requestReview(in: controller)
      result(nil)
    }
  }
}
