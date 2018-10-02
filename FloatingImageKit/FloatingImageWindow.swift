import Cocoa


protocol MouseTrackableView {}

extension MouseTrackableView where Self: NSView
{
    func renewTrackArea() {
        if !trackingAreas.isEmpty {
            for area in trackingAreas {
                removeTrackingArea(area)
            }
        }
        if bounds.size.width == 0 || bounds.size.height == 0 { return }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .mouseMoved,
            .activeInActiveApp,
            .assumeInside
        ]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
    }
}


public class FloatingImageWindowController: NSWindowController
{
    
    class public func openWindowWithImage(image: NSImage) -> FloatingImageWindowController
    {
        let bundle = Bundle(for: self)
        let storyboard = NSStoryboard.init(name: "FloatingImage", bundle: bundle)

        let wc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("FloatingImageWindowController")) as! FloatingImageWindowController
        (wc.contentViewController as! FloatingImageViewController).imageView.image = image

        if let window = wc.window {
            window.orderFront(nil)
            var newFrame = window.frame
            newFrame.size = image.size
            window.setFrame(newFrame, display: true)
        }
        return wc
    }
    
    override open func windowDidLoad()
    {
        super.windowDidLoad()
        
        if let window = self.window as? FloatingImageWindow {
            window.setTransparentMode()
        }
        self.window?.level = .floating
    }
}

public class FloatingImageWindow: NSWindow
{

    public func setTransparentMode()
    {
        if !self.isOpaque { return }

        self.contentView!.wantsLayer = true
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.makeKeyAndOrderFront(nil)
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true

        self.styleMask = [.borderless]
    }

    public func setNormalMode()
    {
        if self.isOpaque { return }
        self.backgroundColor = NSColor.gray
        self.isOpaque = true
        self.styleMask = [.resizable, .closable,]
        self.titleVisibility = .hidden
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.closeButton)?.isHidden = false

        
    }
    
}

public class FloatingImageViewController: NSViewController
{
    @IBOutlet weak var imageView: NSImageView!


}

public class FloatingImageView: NSImageView, MouseTrackableView
{
    public var initialLocation: NSPoint = NSPoint(x: 0, y: 0)

    override public func updateTrackingAreas() {
        renewTrackArea()
    }

    override public func mouseDown(with event: NSEvent)
    {
        if let window = self.window
        {
            self.initialLocation = NSEvent.mouseLocation
            self.initialLocation.x -= window.frame.origin.x
            self.initialLocation.y -= window.frame.origin.y
        }
    }
    
    override public func mouseDragged(with event: NSEvent)
    {
        let currentLocation: NSPoint = NSEvent.mouseLocation
        var newOrigin: NSPoint = NSZeroPoint
        newOrigin.x = currentLocation.x - self.initialLocation.x
        newOrigin.y = currentLocation.y - self.initialLocation.y
        self.window?.setFrameOrigin(newOrigin)
    }

    override public func scrollWheel(with event: NSEvent)
    {
        if event.scrollingDeltaY > 0 {
            if (self.window?.alphaValue)! >= CGFloat(1.0) { return }
            self.window?.alphaValue += 0.2
        } else if event.scrollingDeltaY < 0 {
            if (self.window?.alphaValue)! < CGFloat(0.3) { return }
            self.window?.alphaValue -= 0.2
        }
    }
    
    @IBAction public func toggleBezel(_ sender: Any)
    {
        let hasBezel = self.imageFrameStyle != .none
        self.imageFrameStyle = hasBezel ? .none : .grayBezel
        if let menuItem = sender as? NSMenuItem {
            menuItem.state = self.imageFrameStyle == .none ? .off : .on
        }
    }

    @IBAction public func toggleShadow(_ sender: Any)
    {
        if let window = self.window {
            window.hasShadow = !window.hasShadow
            if let menuItem = sender as? NSMenuItem {
                menuItem.state = window.hasShadow ? .on : .off
            }
        }
    }

    override public func mouseMoved(with event: NSEvent)
    {
        guard let window = self.window as? FloatingImageWindow else { return }

        let optKey = NSEvent.modifierFlags.contains([NSEvent.ModifierFlags.option])
        !optKey ? window.setTransparentMode() : window.setNormalMode()
    }
    
    override public func mouseEntered(with event: NSEvent)
    {
        guard let window = self.window as? FloatingImageWindow else { return }
        let optKey = NSEvent.modifierFlags.contains([NSEvent.ModifierFlags.option])
        if optKey {
            window.setNormalMode()
        }
    }
    override public func mouseExited(with event: NSEvent)
    {
        guard let window = self.window as? FloatingImageWindow else { return }
        window.setTransparentMode()

    }

    override public func keyDown(with event: NSEvent)
    {
        let optKey = NSEvent.modifierFlags.contains([NSEvent.ModifierFlags.option])
        guard let window = self.window as? FloatingImageWindow else { return }
        window.setNormalMode()
    }
}
