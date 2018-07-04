import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    var windowController:FilterShowcaseWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.windowController = FilterShowcaseWindowController(windowNibName:NSNib.Name(rawValue: "FilterShowcaseWindowController"))
        self.windowController?.showWindow(self)
    }
}

