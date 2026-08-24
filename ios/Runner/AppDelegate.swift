import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Application-level method channel used by the Flutter App Review flow.
    // The native side presents Apple's SYSTEM review prompt via
    // `AppStore.requestReview(in:)`; it does not add any purchase/StoreKit
    // transaction code. Keep in sync with lib/services/app_review_service.dart.
    let channel = FlutterMethodChannel(
      name: "contextforge/review",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "requestReview":
        AppDelegate.requestSystemReview(result: result)
      case "getVersion":
        result(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Asks Apple to present the system review prompt (iOS 16.0+).
  ///
  /// Apple decides whether the prompt is actually shown and how often. We do
  /// not assume a rating/review was submitted, and we never read the user's
  /// rating. On older iOS versions this is a graceful no-op.
  private static func requestSystemReview(result: @escaping FlutterResult) {
    guard #available(iOS 16.0, *),
          let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      result(nil)
      return
    }
    Task { @MainActor in
      AppStore.requestReview(in: scene)
      result(nil)
    }
  }
}
