import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate, FlutterStreamHandler {
  private var securityEvents: FlutterEventSink?
  private var screenshotObserver: NSObjectProtocol?
  private var captureObserver: NSObjectProtocol?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let flutterVC = window?.rootViewController as? FlutterViewController else { return }

    let eventChannel = FlutterEventChannel(
      name: "app_creditos/screen_security_events",
      binaryMessenger: flutterVC.binaryMessenger
    )
    eventChannel.setStreamHandler(self)

    screenshotObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.securityEvents?(["type": "screenshot"])
    }

    captureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: UIScreen.main,
      queue: .main
    ) { [weak self] _ in
      self?.securityEvents?([
        "type": "capture_state",
        "isCaptured": UIScreen.main.isCaptured
      ])
    }
  }

  deinit {
    if let screenshotObserver {
      NotificationCenter.default.removeObserver(screenshotObserver)
    }
    if let captureObserver {
      NotificationCenter.default.removeObserver(captureObserver)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    securityEvents = events
    events([
      "type": "capture_state",
      "isCaptured": UIScreen.main.isCaptured
    ])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    securityEvents = nil
    return nil
  }

}
