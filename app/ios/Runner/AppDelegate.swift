import CoreLocation
import Flutter
import MultipeerConnectivity
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
    let registry = engineBridge.pluginRegistry
    if let r = registry.registrar(forPlugin: "HeadingPlugin") { HeadingPlugin.register(with: r) }
    if let r = registry.registrar(forPlugin: "WifiLinkPlugin") { WifiLinkPlugin.register(with: r) }
    if let r = registry.registrar(forPlugin: "MultipeerPlugin") { MultipeerPlugin.register(with: r) }
    if let r = registry.registrar(forPlugin: "IncomingFiles") { IncomingFiles.shared.register(with: r) }
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
      // joinOnce = false: with joinOnce iOS hides the current network, and the
      // spike saw it accept a network and never join (2 of 12); Dart verifies.
      config.joinOnce = (args?["joinOnce"] as? Bool) ?? false
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

/// `horyzontal/mpc`: iPhone to iPhone layer transfer over Multipeer
/// Connectivity. The host advertises a one-time token from its QR; the client
/// browses for exactly that token. Bytes go both ways as reliable messages;
/// the Dart side runs its AES-GCM channel on top.
class MultipeerPlugin: NSObject, FlutterStreamHandler, MCSessionDelegate,
  MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate
{
  private static let service = "hrz-xfer"
  private var sink: FlutterEventSink?
  private var peer: MCPeerID?
  private var session: MCSession?
  private var advertiser: MCNearbyServiceAdvertiser?
  private var browser: MCNearbyServiceBrowser?
  private var token = ""

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = MultipeerPlugin()
    let methods = FlutterMethodChannel(name: "horyzontal/mpc", binaryMessenger: registrar.messenger())
    methods.setMethodCallHandler(plugin.handle)
    FlutterEventChannel(name: "horyzontal/mpc/events", binaryMessenger: registrar.messenger())
      .setStreamHandler(plugin)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  private func emit(_ event: [String: Any]) {
    DispatchQueue.main.async { self.sink?(event) }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "host", "join":
      stop()
      token = args?["token"] as? String ?? ""
      let me = MCPeerID(displayName: "hrz-\(token.prefix(4))-\(Int.random(in: 1000...9999))")
      peer = me
      let s = MCSession(peer: me, securityIdentity: nil, encryptionPreference: .required)
      s.delegate = self
      session = s
      if call.method == "host" {
        let a = MCNearbyServiceAdvertiser(
          peer: me, discoveryInfo: ["t": token], serviceType: MultipeerPlugin.service)
        a.delegate = self
        a.startAdvertisingPeer()
        advertiser = a
      } else {
        let b = MCNearbyServiceBrowser(peer: me, serviceType: MultipeerPlugin.service)
        b.delegate = self
        b.startBrowsingForPeers()
        browser = b
      }
      result(nil)
    case "send":
      guard let s = session, let data = call.arguments as? FlutterStandardTypedData,
        !s.connectedPeers.isEmpty
      else {
        result(FlutterError(code: "not_connected", message: nil, details: nil))
        return
      }
      do {
        try s.send(data.data, toPeers: s.connectedPeers, with: .reliable)
        result(nil)
      } catch {
        result(FlutterError(code: "send_failed", message: error.localizedDescription, details: nil))
      }
    case "stop":
      stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func stop() {
    advertiser?.stopAdvertisingPeer()
    browser?.stopBrowsingForPeers()
    session?.disconnect()
    advertiser = nil
    browser = nil
    session = nil
  }

  // Host: accept only a peer that knows the token (sent as invitation context).
  func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {
    let ok = context.flatMap { String(data: $0, encoding: .utf8) } == token
    invitationHandler(ok, ok ? session : nil)
    if ok { advertiser.stopAdvertisingPeer() }
  }

  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    emit(["type": "error", "message": error.localizedDescription])
  }

  // Client: invite the host advertising our token.
  func browser(
    _ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?
  ) {
    guard info?["t"] == token, let s = session else { return }
    browser.invitePeer(peerID, to: s, withContext: token.data(using: .utf8), timeout: 30)
    browser.stopBrowsingForPeers()
  }

  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

  func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
    emit(["type": "error", "message": error.localizedDescription])
  }

  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connected: emit(["type": "connected"])
    case .notConnected: emit(["type": "disconnected"])
    default: break
    }
  }

  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    emit(["type": "data", "bytes": FlutterStandardTypedData(bytes: data)])
  }

  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
