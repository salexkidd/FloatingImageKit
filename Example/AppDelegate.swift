import Cocoa
import FloatingImageKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    @IBAction func newWindow(_ sender: Any)
    {
        let wc = FloatingImageWindowController.openWindowWithImage(image: NSImage(named: "testImage")!)
        wc.showWindow(sender)
    }
    
}

