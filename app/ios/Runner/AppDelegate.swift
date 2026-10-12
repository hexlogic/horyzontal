import CoreLocation
import Flutter
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HeadingPlugin") {
      HeadingPlugin.register(with: registrar)
    }
  }
}

/// `horyzontal/heading`: magnetic heading of the top edge of the device from
/// CLLocationManager. Heading needs no location permission; true north is
/// applied in Dart from the WMM model so both platforms agree.
class HeadingPlugin: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(name: "horyzontal/heading", binaryMessenger: registrar.messenger())
    channel.setStreamHandler(HeadingPlugin())
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard CLLocationManager.headingAvailable() else {
      // Through the sink: an error returned from onListen never reaches the stream.
      events(FlutterError(code: "unavailable", message: "No magnetometer", details: nil))
      return nil
    }
    sink = events
    manager.delegate = self
    manager.headingFilter = 0.5
    manager.headingOrientation = .portrait
    manager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    sink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
    // headingAccuracy < 0 means the reading is invalid (needs calibration).
    sink?([
      "heading": heading.magneticHeading,
      "accuracy": heading.headingAccuracy,
    ])
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    return true
  }
}
