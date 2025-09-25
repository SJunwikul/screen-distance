import Cocoa
import QuartzCore

protocol WarningModalDelegate: AnyObject {
    func modalDidClose()
}

class WarningModalController: NSObject {
    weak var delegate: WarningModalDelegate?
    
    private var warningWindow: NSWindow?
    private var distanceLabel: NSTextField?
    private var warningLabel: NSTextField?
    private var instructionLabel: NSTextField?
    private var arasakaLogoLabel: NSTextField?
    private var statusLabel: NSTextField?
    private var currentDistance: Double = 0
    private var updateTimer: Timer?
    private var glitchTimer: Timer?
    private var scanlineView: NSView?
    private var borderViews: [NSView] = []
    
    // Cyberpunk color scheme - Arasaka Red/Green Theme
    private let arasakaRed = NSColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 1.0)
    private let arasakaRedDark = NSColor(red: 0.8, green: 0.0, blue: 0.2, alpha: 1.0)
    private let arasakaGreen = NSColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 1.0)
    private let arasakaGreenDark = NSColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 1.0)
    private let arasakaDark = NSColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.95)
    private let arasakaGlow = NSColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 0.3)
    
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
        let windowRect = NSRect(x: 0, y: 0, width: 500, height: 400)
        
        warningWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = warningWindow else { return }
        
        window.backgroundColor = arasakaDark
        window.isOpaque = false
        window.hasShadow = true
        window.canHide = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create content view with cyberpunk styling
        let contentView = NSView(frame: windowRect)
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 0
        contentView.layer?.masksToBounds = false
        contentView.layer?.backgroundColor = arasakaDark.cgColor
        
        // Add geometric border elements
        createCyberpunkBorders(in: contentView)
        
        // Add scanline effect
        createScanlineEffect(in: contentView)
        
        // Add glow effect
        contentView.layer?.shadowColor = arasakaRed.cgColor
        contentView.layer?.shadowOffset = CGSize.zero
        contentView.layer?.shadowRadius = 20
        contentView.layer?.shadowOpacity = 0.5
        
        // Arasaka Corporation Header
        arasakaLogoLabel = NSTextField(frame: NSRect(x: 20, y: 350, width: 460, height: 30))
        arasakaLogoLabel?.stringValue = "荒坂 ARASAKA CORPORATION"
        arasakaLogoLabel?.alignment = .center
        arasakaLogoLabel?.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        arasakaLogoLabel?.textColor = arasakaRed
        arasakaLogoLabel?.backgroundColor = .clear
        arasakaLogoLabel?.isBezeled = false
        arasakaLogoLabel?.isEditable = false
        arasakaLogoLabel?.isSelectable = false
        contentView.addSubview(arasakaLogoLabel!)
        
        // Status indicator
        statusLabel = NSTextField(frame: NSRect(x: 20, y: 320, width: 460, height: 20))
        statusLabel?.stringValue = "[ PROXIMITY ALERT SYSTEM ACTIVE ]"
        statusLabel?.alignment = .center
        statusLabel?.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        statusLabel?.textColor = arasakaRed
        statusLabel?.backgroundColor = .clear
        statusLabel?.isBezeled = false
        statusLabel?.isEditable = false
        statusLabel?.isSelectable = false
        contentView.addSubview(statusLabel!)
        
        // Cyberpunk warning icon (using text)
        let iconView = NSTextField(frame: NSRect(x: 200, y: 270, width: 100, height: 40))
        iconView.stringValue = "⚠ 警告 ⚠"
        iconView.alignment = .center
        iconView.font = NSFont.monospacedSystemFont(ofSize: 24, weight: .bold)
        iconView.textColor = arasakaRed
        iconView.backgroundColor = .clear
        iconView.isBezeled = false
        iconView.isEditable = false
        iconView.isSelectable = false
        contentView.addSubview(iconView)
        
        // Cyberpunk warning title
        warningLabel = NSTextField(frame: NSRect(x: 20, y: 230, width: 460, height: 30))
        warningLabel?.stringValue = "CRITICAL PROXIMITY BREACH DETECTED"
        warningLabel?.alignment = .center
        warningLabel?.font = NSFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        warningLabel?.textColor = arasakaRed
        warningLabel?.backgroundColor = .clear
        warningLabel?.isBezeled = false
        warningLabel?.isEditable = false
        warningLabel?.isSelectable = false
        contentView.addSubview(warningLabel!)
        
        // Cyberpunk distance display with frame
        let distanceFrame = NSView(frame: NSRect(x: 50, y: 150, width: 400, height: 60))
        distanceFrame.wantsLayer = true
        distanceFrame.layer?.borderColor = arasakaRed.cgColor
        distanceFrame.layer?.borderWidth = 2
        distanceFrame.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.7).cgColor
        contentView.addSubview(distanceFrame)
        
        distanceLabel = NSTextField(frame: NSRect(x: 60, y: 165, width: 380, height: 30))
        distanceLabel?.stringValue = "DISTANCE: -- CM"
        distanceLabel?.alignment = .center
        distanceLabel?.font = NSFont.monospacedSystemFont(ofSize: 20, weight: .bold)
        distanceLabel?.textColor = arasakaRed
        distanceLabel?.backgroundColor = .clear
        distanceLabel?.isBezeled = false
        distanceLabel?.isEditable = false
        distanceLabel?.isSelectable = false
        contentView.addSubview(distanceLabel!)
        
        // Cyberpunk instruction text
        instructionLabel = NSTextField(frame: NSRect(x: 30, y: 80, width: 440, height: 60))
        instructionLabel?.stringValue = ">> MAINTAIN MINIMUM 50CM DISTANCE FROM DISPLAY\n>> BIOMETRIC MONITORING: ACTIVE\n>> COMPLIANCE REQUIRED FOR SYSTEM ACCESS"
        instructionLabel?.alignment = .left
        instructionLabel?.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        instructionLabel?.textColor = arasakaRedDark
        instructionLabel?.backgroundColor = .clear
        instructionLabel?.isBezeled = false
        instructionLabel?.isEditable = false
        instructionLabel?.isSelectable = false
        instructionLabel?.usesSingleLineMode = false
        instructionLabel?.maximumNumberOfLines = 4
        contentView.addSubview(instructionLabel!)
        
        // Arasaka footer with Japanese text
        let footerLabel = NSTextField(frame: NSRect(x: 20, y: 30, width: 460, height: 40))
        footerLabel.stringValue = "健康管理システム - HEALTH MONITORING SYSTEM\n[ AUTHORIZED PERSONNEL ONLY - 認可された職員のみ ]"
        footerLabel.alignment = .center
        footerLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        footerLabel.textColor = arasakaRed.withAlphaComponent(0.7)
        footerLabel.backgroundColor = .clear
        footerLabel.isBezeled = false
        footerLabel.isEditable = false
        footerLabel.isSelectable = false
        footerLabel.usesSingleLineMode = false
        footerLabel.maximumNumberOfLines = 2
        contentView.addSubview(footerLabel)
        
        window.contentView = contentView
        
        // Start cyberpunk effects
        startCyberpunkEffects()
    }
    
    private func updateDistanceDisplay() {
        guard let distanceLabel = distanceLabel else { return }
        
        DispatchQueue.main.async {
            let distanceText = String(format: "DISTANCE: %.1f CM", self.currentDistance)
            distanceLabel.stringValue = distanceText
            
            // Cyberpunk color coding based on threat level
            if self.currentDistance < 30 {
                distanceLabel.textColor = self.arasakaRed
                self.statusLabel?.stringValue = "[ CRITICAL BREACH - IMMEDIATE ACTION REQUIRED ]"
                self.statusLabel?.textColor = self.arasakaRed
                self.updateVisualTheme(isWarning: true, isCritical: true)
            } else if self.currentDistance < 50 {
                distanceLabel.textColor = NSColor.systemYellow
                self.statusLabel?.stringValue = "[ WARNING - PROXIMITY VIOLATION DETECTED ]"
                self.statusLabel?.textColor = NSColor.systemYellow
                self.updateVisualTheme(isWarning: true, isCritical: false)
            } else {
                distanceLabel.textColor = self.arasakaGreen
                self.statusLabel?.stringValue = "[ SAFE - DISTANCE COMPLIANCE ACHIEVED ]"
                self.statusLabel?.textColor = self.arasakaGreen
                self.updateVisualTheme(isWarning: false, isCritical: false)
            }
        }
    }
    
    private func startUpdateTimer() {
        stopUpdateTimer()
        // Timer for cyberpunk visual effects
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.cyberpunkPulse()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        glitchTimer?.invalidate()
        glitchTimer = nil
    }
    
    private func cyberpunkPulse() {
        guard let window = warningWindow else { return }
        
        // Pulse the glow effect
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.allowsImplicitAnimation = true
            window.contentView?.layer?.shadowOpacity = 0.8
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.4
                context.allowsImplicitAnimation = true
                window.contentView?.layer?.shadowOpacity = 0.5
            }
        }
        
        // Flicker border elements
        for borderView in self.borderViews {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                borderView.animator().alphaValue = 0.6
            } completionHandler: {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    borderView.animator().alphaValue = 1.0
                }
            }
        }
    }
    
    private func animateWarningAppearance() {
        guard let window = warningWindow else { return }
        
        // Cyberpunk materialization effect
        window.alphaValue = 0
        window.contentView?.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
        
        // Glitch effect on appearance
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                window.setFrameOrigin(NSPoint(x: window.frame.origin.x + (i % 2 == 0 ? 2 : -2), y: window.frame.origin.y))
            }
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 0.98
            window.contentView?.layer?.transform = CATransform3DIdentity
        }
    }
    
    private func animateWarningDisappearance(completion: @escaping () -> Void) {
        guard let window = warningWindow else {
            completion()
            return
        }
        
        // Cyberpunk dematerialization with glitch effect
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                window.setFrameOrigin(NSPoint(x: window.frame.origin.x + (i % 2 == 0 ? 5 : -5), y: window.frame.origin.y))
            }
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            window.contentView?.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1.0)
        } completionHandler: {
            completion()
        }
    }
    
    // MARK: - Theme Updates
    
    private func updateVisualTheme(isWarning: Bool, isCritical: Bool) {
        guard let window = warningWindow else { return }
        
        let primaryColor: NSColor
        let secondaryColor: NSColor
        let glowColor: NSColor
        
        if isWarning {
            primaryColor = arasakaRed
            secondaryColor = arasakaRedDark
            glowColor = NSColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 0.3)
        } else {
            primaryColor = arasakaGreen
            secondaryColor = arasakaGreenDark
            glowColor = NSColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 0.3)
        }
        
        // Update all visual elements
        DispatchQueue.main.async {
            // Update header color
            self.arasakaLogoLabel?.textColor = primaryColor
            
            // Update instruction text color
            self.instructionLabel?.textColor = secondaryColor
            
            // Update footer color
            if let footerViews = window.contentView?.subviews {
                for view in footerViews {
                    if let textField = view as? NSTextField,
                       textField.stringValue.contains("健康管理システム") {
                        textField.textColor = primaryColor.withAlphaComponent(0.7)
                    }
                }
            }
            
            // Update border colors
            for borderView in self.borderViews {
                borderView.layer?.borderColor = primaryColor.cgColor
                if borderView.layer?.backgroundColor != NSColor.clear.cgColor {
                    borderView.layer?.backgroundColor = primaryColor.cgColor
                }
            }
            
            // Update distance frame border
            if let distanceFrame = window.contentView?.subviews.first(where: { $0.frame.height == 60 && $0.layer?.borderWidth == 2 }) {
                distanceFrame.layer?.borderColor = primaryColor.cgColor
            }
            
            // Update scanline color
            self.scanlineView?.layer?.backgroundColor = primaryColor.withAlphaComponent(0.8).cgColor
            self.scanlineView?.layer?.shadowColor = primaryColor.cgColor
            
            // Update window glow
            window.contentView?.layer?.shadowColor = primaryColor.cgColor
        }
    }
    
    // MARK: - Cyberpunk Visual Effects
    
    private func createCyberpunkBorders(in contentView: NSView) {
        let borderWidth: CGFloat = 3
        let cornerSize: CGFloat = 30
        
        // Top-left corner
        let topLeftCorner = NSView(frame: NSRect(x: 0, y: contentView.frame.height - cornerSize, width: cornerSize, height: cornerSize))
        topLeftCorner.wantsLayer = true
        topLeftCorner.layer?.borderColor = arasakaRed.cgColor
        topLeftCorner.layer?.borderWidth = borderWidth
        topLeftCorner.layer?.backgroundColor = NSColor.clear.cgColor
        contentView.addSubview(topLeftCorner)
        borderViews.append(topLeftCorner)
        
        // Top-right corner
        let topRightCorner = NSView(frame: NSRect(x: contentView.frame.width - cornerSize, y: contentView.frame.height - cornerSize, width: cornerSize, height: cornerSize))
        topRightCorner.wantsLayer = true
        topRightCorner.layer?.borderColor = arasakaRed.cgColor
        topRightCorner.layer?.borderWidth = borderWidth
        topRightCorner.layer?.backgroundColor = NSColor.clear.cgColor
        contentView.addSubview(topRightCorner)
        borderViews.append(topRightCorner)
        
        // Bottom-left corner
        let bottomLeftCorner = NSView(frame: NSRect(x: 0, y: 0, width: cornerSize, height: cornerSize))
        bottomLeftCorner.wantsLayer = true
        bottomLeftCorner.layer?.borderColor = arasakaRed.cgColor
        bottomLeftCorner.layer?.borderWidth = borderWidth
        bottomLeftCorner.layer?.backgroundColor = NSColor.clear.cgColor
        contentView.addSubview(bottomLeftCorner)
        borderViews.append(bottomLeftCorner)
        
        // Bottom-right corner
        let bottomRightCorner = NSView(frame: NSRect(x: contentView.frame.width - cornerSize, y: 0, width: cornerSize, height: cornerSize))
        bottomRightCorner.wantsLayer = true
        bottomRightCorner.layer?.borderColor = arasakaRed.cgColor
        bottomRightCorner.layer?.borderWidth = borderWidth
        bottomRightCorner.layer?.backgroundColor = NSColor.clear.cgColor
        contentView.addSubview(bottomRightCorner)
        borderViews.append(bottomRightCorner)
        
        // Add accent lines
        let accentLine1 = NSView(frame: NSRect(x: 50, y: contentView.frame.height - 2, width: 100, height: 2))
        accentLine1.wantsLayer = true
        accentLine1.layer?.backgroundColor = arasakaRed.cgColor
        contentView.addSubview(accentLine1)
        borderViews.append(accentLine1)
        
        let accentLine2 = NSView(frame: NSRect(x: contentView.frame.width - 150, y: 0, width: 100, height: 2))
        accentLine2.wantsLayer = true
        accentLine2.layer?.backgroundColor = arasakaRed.cgColor
        contentView.addSubview(accentLine2)
        borderViews.append(accentLine2)
    }
    
    private func createScanlineEffect(in contentView: NSView) {
        scanlineView = NSView(frame: NSRect(x: 0, y: 0, width: contentView.frame.width, height: 2))
        scanlineView?.wantsLayer = true
        scanlineView?.layer?.backgroundColor = arasakaRed.withAlphaComponent(0.8).cgColor
        scanlineView?.layer?.shadowColor = arasakaRed.cgColor
        scanlineView?.layer?.shadowOffset = CGSize.zero
        scanlineView?.layer?.shadowRadius = 5
        scanlineView?.layer?.shadowOpacity = 1.0
        contentView.addSubview(scanlineView!)
        
        // Animate scanline
        animateScanline()
    }
    
    private func animateScanline() {
        guard let scanlineView = scanlineView else { return }
        
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = 0
        animation.toValue = warningWindow?.frame.height ?? 400
        animation.duration = 3.0
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        scanlineView.layer?.add(animation, forKey: "scanline")
    }
    
    private func startCyberpunkEffects() {
        // Start glitch timer for random glitch effects
        glitchTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.randomGlitchEffect()
        }
    }
    
    private func randomGlitchEffect() {
        guard let window = warningWindow else { return }
        
        // Random glitch displacement
        let originalOrigin = window.frame.origin
        
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                let randomX = originalOrigin.x + CGFloat.random(in: -3...3)
                let randomY = originalOrigin.y + CGFloat.random(in: -2...2)
                window.setFrameOrigin(NSPoint(x: randomX, y: randomY))
            }
        }
        
        // Return to original position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            window.setFrameOrigin(originalOrigin)
        }
        
        // Random text glitch on labels
        if let warningLabel = warningLabel, Bool.random() {
            let originalText = warningLabel.stringValue
            warningLabel.stringValue = "C̸R̷I̴T̶I̵C̸A̷L̴ ̶P̵R̴O̸X̷I̵M̶I̵T̶Y̴ ̸B̷R̵E̴A̸C̶H̵"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                warningLabel.stringValue = originalText
            }
        }
    }
}
