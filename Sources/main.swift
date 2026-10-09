import AppKit
import Carbon.HIToolbox
import ServiceManagement

// MARK: - Window actions

enum Action: UInt32, CaseIterable {
    case leftHalf = 1, rightHalf, maximize

    var keyCode: Int {
        switch self {
        case .leftHalf: return kVK_LeftArrow
        case .rightHalf: return kVK_RightArrow
        case .maximize: return kVK_UpArrow
        }
    }

    /// Target rect inside the screen's visible frame (Cocoa coordinates, bottom-left origin).
    func rect(in f: NSRect) -> NSRect {
        switch self {
        case .leftHalf: return NSRect(x: f.minX, y: f.minY, width: (f.width / 2).rounded(), height: f.height)
        case .rightHalf:
            let w = (f.width / 2).rounded()
            return NSRect(x: f.maxX - w, y: f.minY, width: w, height: f.height)
        case .maximize: return f
        }
    }
}

enum WindowMover {
    static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &value) == .success else { return nil }
        return (value as! AXUIElement)
    }

    static func frame(of window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?, sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success else { return nil }
        var pos = CGPoint.zero, size = CGSize.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &pos)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        return CGRect(origin: pos, size: size)
    }

    static func setFrame(_ window: AXUIElement, _ r: CGRect) {
        var pos = r.origin, size = r.size
        let posVal = AXValueCreate(.cgPoint, &pos)!, sizeVal = AXValueCreate(.cgSize, &size)!
        // Size -> position -> size so the window isn't clamped by the old screen edge.
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal)
    }

    /// AX uses a top-left origin anchored to the primary screen; Cocoa uses bottom-left.
    static func flip(_ r: CGRect) -> CGRect {
        let h = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: r.minX, y: h - r.maxY, width: r.width, height: r.height)
    }

    static func perform(_ action: Action) {
        guard let window = focusedWindow(), let axFrame = frame(of: window) else { return }
        let cocoaFrame = flip(axFrame)
        let center = CGPoint(x: cocoaFrame.midX, y: cocoaFrame.midY)
        let screen = NSScreen.screens.first { $0.frame.contains(center) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        setFrame(window, flip(action.rect(in: visible)))
    }
}

// MARK: - Hotkeys (ctrl + option + arrow)

func registerHotKeys() {
    var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
        var id = EventHotKeyID()
        GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                          nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
        if let action = Action(rawValue: id.id) { WindowMover.perform(action) }
        return noErr
    }, 1, &spec, nil, nil)

    let mods = UInt32(controlKey | optionKey)
    for action in Action.allCases {
        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: OSType(0x534E4150) /* 'SNAP' */, id: action.rawValue)
        RegisterEventHotKey(UInt32(action.keyCode), mods, id, GetApplicationEventTarget(), 0, &ref)
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")

    func applicationDidFinishLaunching(_ note: Notification) {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
        registerHotKeys()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Snap")
        let menu = NSMenu()
        menu.addItem(withTitle: "⌃⌥←  Left half", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "⌃⌥→  Right half", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "⌃⌥↑  Maximize", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(withTitle: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch { NSLog("Snap: login item error: \(error)") }
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
