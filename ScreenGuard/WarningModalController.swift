import Cocoa

protocol WarningModalDelegate: AnyObject {
    func modalDidClose()
}

class WarningModalController: NSObject {
    weak var delegate: WarningModalDelegate?
    
    private var warningWindow: NSWindow?
    private var distanceLabel: NSTextField?
    private var warningLabel: NSTextField?
    private var instructionLabel: NSTextField?
    private var currentDistance: Double = 0
    private var updateTimer: Timer?
    
    func showWarning(distance: Double) {
        currentDistance = distance
        
        if warningWindow == nil {
            createWarningWindow()
        }
        
        updateDistanceDisplay()
        
        guard let window = warningWindow else { return }
        
        // Position window in center of screen
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            let windowRect = window.frame
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Show window with high level to appear over all other windows
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        // Start update timer for real-time distance display
        startUpdateTimer()
        
        // Add some visual effects
        animateWarningAppearance()
    }
    
    func hideWarning() {
        stopUpdateTimer()
        
        animateWarningDisappearance { [weak self] in
            self?.warningWindow?.orderOut(nil)
            self?.warningWindow = nil
            self?.delegate?.modalDidClose()
        }
    }
    
    func updateDistance(_ distance: Double) {
        currentDistance = distance
        // Update display immediately when new distance is received
        DispatchQueue.main.async {
            self.updateDistanceDisplay()
        }
    }
    
    private func createWarningWindow() {
        let windowRect = NSRect(x: 0, y: 0, width: 400, height: 300)
        
        warningWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = warningWindow else { return }
        
        window.backgroundColor = NSColor.systemRed.withAlphaComponent(0.95)
        window.isOpaque = false
        window.hasShadow = true
        window.canHide = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create content view
        let contentView = NSView(frame: windowRect)
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 20
        contentView.layer?.masksToBounds = true
        
        // Warning icon
        let iconView = NSImageView(frame: NSRect(x: 175, y: 220, width: 50, height: 50))
        iconView.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning")
        iconView.contentTintColor = .white
        iconView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addSubview(iconView)
        
        // Warning title
        warningLabel = NSTextField(frame: NSRect(x: 20, y: 180, width: 360, height: 30))
        warningLabel?.stringValue = "⚠️ TOO CLOSE TO SCREEN!"
        warningLabel?.alignment = .center
        warningLabel?.font = NSFont.boldSystemFont(ofSize: 20)
        warningLabel?.textColor = .white
        warningLabel?.backgroundColor = .clear
        warningLabel?.isBezeled = false
        warningLabel?.isEditable = false
        warningLabel?.isSelectable = false
        contentView.addSubview(warningLabel!)
        
        // Distance display
        distanceLabel = NSTextField(frame: NSRect(x: 20, y: 130, width: 360, height: 40))
        distanceLabel?.stringValue = "Current Distance: -- cm"
        distanceLabel?.alignment = .center
        distanceLabel?.font = NSFont.monospacedSystemFont(ofSize: 24, weight: .medium)
        distanceLabel?.textColor = .white
        distanceLabel?.backgroundColor = .clear
        distanceLabel?.isBezeled = false
        distanceLabel?.isEditable = false
        distanceLabel?.isSelectable = false
        contentView.addSubview(distanceLabel!)
        
        // Instruction text
        instructionLabel = NSTextField(frame: NSRect(x: 20, y: 60, width: 360, height: 60))
        instructionLabel?.stringValue = "Please move back to at least 50cm from your screen.\nThis modal will disappear when you reach a safe distance."
        instructionLabel?.alignment = .center
        instructionLabel?.font = NSFont.systemFont(ofSize: 14)
        instructionLabel?.textColor = .white
        instructionLabel?.backgroundColor = .clear
        instructionLabel?.isBezeled = false
        instructionLabel?.isEditable = false
        instructionLabel?.isSelectable = false
        instructionLabel?.usesSingleLineMode = false
        instructionLabel?.maximumNumberOfLines = 3
        contentView.addSubview(instructionLabel!)
        
        // Health tip
        let healthTipLabel = NSTextField(frame: NSRect(x: 20, y: 20, width: 360, height: 30))
        healthTipLabel.stringValue = "💡 Tip: Follow the 20-20-20 rule for better eye health"
        healthTipLabel.alignment = .center
        healthTipLabel.font = NSFont.systemFont(ofSize: 12)
        healthTipLabel.textColor = NSColor.white.withAlphaComponent(0.8)
        healthTipLabel.backgroundColor = .clear
        healthTipLabel.isBezeled = false
        healthTipLabel.isEditable = false
        healthTipLabel.isSelectable = false
        contentView.addSubview(healthTipLabel)
        
        window.contentView = contentView
    }
    
    private func updateDistanceDisplay() {
        guard let distanceLabel = distanceLabel else { return }
        
        DispatchQueue.main.async {
            let distanceText = String(format: "Current Distance: %.1f cm", self.currentDistance)
            distanceLabel.stringValue = distanceText
            
            // Change color based on distance
            if self.currentDistance < 30 {
                distanceLabel.textColor = NSColor.systemYellow
            } else if self.currentDistance < 50 {
                distanceLabel.textColor = NSColor.systemOrange
            } else {
                distanceLabel.textColor = NSColor.white
            }
        }
    }
    
    private func startUpdateTimer() {
        stopUpdateTimer()
        // Only use timer for visual effects like pulsing, distance updates come from delegate
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pulseWarning()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func pulseWarning() {
        guard let window = warningWindow else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.allowsImplicitAnimation = true
            window.alphaValue = 0.8
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.allowsImplicitAnimation = true
                window.alphaValue = 0.95
            }
        }
    }
    
    private func animateWarningAppearance() {
        guard let window = warningWindow else { return }
        
        window.alphaValue = 0
        window.setFrame(window.frame.insetBy(dx: 50, dy: 50), display: true)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 0.95
            window.animator().setFrame(window.frame.insetBy(dx: -50, dy: -50), display: true)
        }
    }
    
    private func animateWarningDisappearance(completion: @escaping () -> Void) {
        guard let window = warningWindow else {
            completion()
            return
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            window.animator().setFrame(window.frame.insetBy(dx: 20, dy: 20), display: true)
        } completionHandler: {
            completion()
        }
    }
}
