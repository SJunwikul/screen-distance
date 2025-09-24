import Cocoa
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem!
    var distanceMonitor: DistanceMonitor!
    var warningModal: WarningModalController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "ScreenGuard")
            button.action = #selector(statusBarButtonClicked(_:))
        }
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Distance Monitor: Starting...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit ScreenGuard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        
        // Initialize distance monitor
        distanceMonitor = DistanceMonitor()
        distanceMonitor.delegate = self
        
        // Request camera permission and start monitoring
        requestCameraPermission()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        distanceMonitor?.stopMonitoring()
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        // Menu will be shown automatically
    }
    
    @objc func showPreferences() {
        // TODO: Implement preferences window
        let alert = NSAlert()
        alert.messageText = "Preferences"
        alert.informativeText = "Preferences window coming soon!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.distanceMonitor.startMonitoring()
                } else {
                    self?.showCameraPermissionAlert()
                }
            }
        }
    }
    
    private func showCameraPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Camera Access Required"
        alert.informativeText = "ScreenGuard needs camera access to monitor your distance from the screen. Please grant camera permission in System Preferences > Privacy & Security > Camera."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Quit")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!)
        }
        NSApplication.shared.terminate(self)
    }
    
    private func updateStatusBarTitle(distance: Double) {
        if let menu = statusBarItem.menu,
           let firstItem = menu.items.first {
            let distanceText = String(format: "Distance: %.1f cm", distance)
            firstItem.title = distanceText
        }
    }
}

// MARK: - DistanceMonitorDelegate
extension AppDelegate: DistanceMonitorDelegate {
    func distanceDidUpdate(_ distance: Double) {
        DispatchQueue.main.async {
            self.updateStatusBarTitle(distance: distance)
            // Also update the modal if it's showing
            self.warningModal?.updateDistance(distance)
        }
    }
    
    func userIsTooClose(_ distance: Double) {
        DispatchQueue.main.async {
            if self.warningModal == nil {
                self.warningModal = WarningModalController()
                self.warningModal?.delegate = self
            }
            self.warningModal?.showWarning(distance: distance)
        }
    }
    
    func userIsAtSafeDistance(_ distance: Double) {
        DispatchQueue.main.async {
            self.warningModal?.hideWarning()
            self.warningModal = nil
        }
    }
}

// MARK: - WarningModalDelegate
extension AppDelegate: WarningModalDelegate {
    func modalDidClose() {
        warningModal = nil
    }
}
