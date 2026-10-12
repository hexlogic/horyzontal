import Flutter
import NetworkExtension
import UIKit

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WifiLinkPlugin") {
      WifiLinkPlugin.register(with: registrar)
    }
  }
}

/// iOS side of `horyzontal/wifi`. iOS cannot host a hotspot, it only joins one
/// through NEHotspotConfiguration (needs the Hotspot Configuration capability).
class WifiLinkPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "horyzontal/wifi", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(WifiLinkPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "join":
      guard let ssid = args?["ssid"] as? String, let psk = args?["psk"] as? String else {
        result(FlutterError(code: "bad_args", message: nil, details: nil))
        return
      }
      let config = NEHotspotConfiguration(ssid: ssid, passphrase: psk, isWEP: false)
      // joinOnce forgets the network when the app goes to background. The spike
      // tries both because iOS is known to join silently-not-at-all with it.
      config.joinOnce = (args?["joinOnce"] as? Bool) ?? true
      NEHotspotConfigurationManager.shared.apply(config) { error in
        DispatchQueue.main.async {
          if let e = error as NSError?,
             !(e.domain == NEHotspotConfigurationErrorDomain
               && e.code == NEHotspotConfigurationError.alreadyAssociated.rawValue) {
            // 7 = userDenied, 8 = internal, 2 = invalidWPAPassphrase, ...
            result(FlutterError(code: "join_failed", message: e.localizedDescription, details: e.code))
          } else {
            result(nil)
          }
        }
      }
    case "currentSsid":
      // Works for networks this app configured (needs Access Wi-Fi Information).
      NEHotspotNetwork.fetchCurrent { network in
        DispatchQueue.main.async { result(network?.ssid) }
      }
    case "leave":
      if let ssid = args?["ssid"] as? String {
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
      }
      result(nil)
    case "startHotspot", "stopHotspot":
      result(FlutterError(code: "unsupported", message: "iOS не може створити точку доступу", details: nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
