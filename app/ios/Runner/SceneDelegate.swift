import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var cover: UIVisualEffectView?

  /// Blurs the window before iOS takes the app switcher snapshot.
  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    guard cover == nil, let window = (scene as? UIWindowScene)?.windows.first else { return }
    let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    v.frame = window.bounds
    v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(v)
    cover = v
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    cover?.removeFromSuperview()
    cover = nil
  }

  /// Files opened with "Share" / "Open in": handed to Dart for import.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    for ctx in URLContexts {
      IncomingFiles.shared.receive(ctx.url)
    }
  }

  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    for ctx in connectionOptions.urlContexts {
      IncomingFiles.shared.receive(ctx.url)
    }
  }
}

/// `horyzontal/incoming`: copies files the system hands us into the app's
/// temporary folder (they may be security-scoped or in an inbox) and passes
/// the paths to Dart, which asks the user before importing.
class IncomingFiles: NSObject, FlutterStreamHandler {
  static let shared = IncomingFiles()
  private var sink: FlutterEventSink?
  private var pending: [String] = []

  func register(with registrar: FlutterPluginRegistrar) {
    FlutterEventChannel(name: "horyzontal/incoming", binaryMessenger: registrar.messenger())
      .setStreamHandler(self)
  }

  func receive(_ url: URL) {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("incoming", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let dest = dir.appendingPathComponent(url.lastPathComponent)
    try? FileManager.default.removeItem(at: dest)
    guard (try? FileManager.default.copyItem(at: url, to: dest)) != nil else { return }
    if let s = sink { s(dest.path) } else { pending.append(dest.path) }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    pending.forEach { events($0) }
    pending.removeAll()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}
