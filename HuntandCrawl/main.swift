import SwiftUI
import SwiftData

// Set up a custom exception handler
NSSetUncaughtExceptionHandler { exception in
    print("UNCAUGHT EXCEPTION: \(exception)")
    print("Reason: \(exception.reason ?? "unknown")")
    print("Stack trace: \(exception.callStackSymbols.joined(separator: "\n"))")
}

// Create and run the app
let app = HuntandCrawlApp()
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)

// Custom app delegate to handle initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    var app: HuntandCrawlApp?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("Application launched successfully")
        app = HuntandCrawlApp()
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

// Custom scene delegate
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        // Initialize our app
        let app = appDelegate.app ?? HuntandCrawlApp()
        
        // Create the SwiftUI hosting controller with MainTabView
        let hostingController = UIHostingController(
            rootView: MainTabView()
                .environment(\.modelContext, app.sharedModelContainer.mainContext)
                .environment(app.networkMonitor)
        )
        
        // Create the window and set the content view
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = hostingController
        self.window = window
        window.makeKeyAndVisible()
        
        print("Scene created with MainTabView as root")
    }
} 