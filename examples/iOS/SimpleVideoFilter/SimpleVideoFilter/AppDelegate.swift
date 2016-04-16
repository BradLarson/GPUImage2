import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Pause camera
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Pause camera
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Resume camera
    }

    func applicationWillTerminate(application: UIApplication) {
        // Pause camera if not already
    }


}

