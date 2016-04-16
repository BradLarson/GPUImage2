import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    var windowController:FilterShowcaseWindowController?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.windowController = FilterShowcaseWindowController(windowNibName:"FilterShowcaseWindowController")
        self.windowController?.showWindow(self)
    }
}

