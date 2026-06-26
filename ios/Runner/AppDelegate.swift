import Flutter
import UIKit
import app_links
import passkeys_darwin
import shared_preferences_foundation
import ua_client_hints
import url_launcher_ios

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        let registry = engineBridge.pluginRegistry

        GeneratedPluginRegistrant.register(with: registry)
        if let registrar = registry.registrar(forPlugin: "AppLinksIosPlugin") {
            AppLinksIosPlugin.register(with: registrar)
        }
        if #available(iOS 16.0, *), let registrar = registry.registrar(forPlugin: "PasskeysPlugin") {
            PasskeysPlugin.register(with: registrar)
        }
        if let registrar = registry.registrar(forPlugin: "SharedPreferencesPlugin") {
            SharedPreferencesPlugin.register(with: registrar)
        }
        if let registrar = registry.registrar(forPlugin: "UAClientHintsPlugin") {
            UAClientHintsPlugin.register(with: registrar)
        }
        if let registrar = registry.registrar(forPlugin: "URLLauncherPlugin") {
            URLLauncherPlugin.register(with: registrar)
        }
    }
}
