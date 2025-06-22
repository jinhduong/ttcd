import SwiftUI
import AppKit

struct KeyEventListenerView: NSViewRepresentable {
    
    var onKeyDown: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyListeningNSView()
        view.onKeyDown = onKeyDown
        
        // We need to delay making this the first responder until the next run loop
        // to ensure the window is ready.
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    // The custom NSView that does the actual key listening.
    class KeyListeningNSView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?
        
        // This view must be able to become the first responder to receive key events.
        override var acceptsFirstResponder: Bool {
            return true
        }
        
        // This is the core method that captures the key down event.
        override func keyDown(with event: NSEvent) {
            // Forward the event to our SwiftUI view via the closure.
            onKeyDown?(event)
        }
    }
} 