import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Pause camera
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Pause camera
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume camera
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Pause camera if not already
    }


}

