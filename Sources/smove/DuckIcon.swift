import AppKit

enum DuckIcon {
    static func make(size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        let bodyColor = NSColor(red: 0.88, green: 0.04, blue: 0.05, alpha: 1)
        let wingColor = NSColor(red: 0.65, green: 0.00, blue: 0.03, alpha: 1)
        let beakColor = NSColor(red: 1.00, green: 0.55, blue: 0.05, alpha: 1)
        let eyeColor = NSColor.black

        let scaleX = size.width / 24
        let scaleY = size.height / 18

        func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
            NSRect(x: x * scaleX, y: y * scaleY, width: width * scaleX, height: height * scaleY)
        }

        bodyColor.setFill()
        NSBezierPath(ovalIn: rect(2, 2, 16, 10)).fill()
        NSBezierPath(ovalIn: rect(10, 8, 8, 8)).fill()

        beakColor.setFill()
        let beak = NSBezierPath()
        beak.move(to: NSPoint(x: 18 * scaleX, y: 13 * scaleY))
        beak.line(to: NSPoint(x: 23 * scaleX, y: 11.5 * scaleY))
        beak.line(to: NSPoint(x: 18 * scaleX, y: 10 * scaleY))
        beak.close()
        beak.fill()

        wingColor.setFill()
        NSBezierPath(ovalIn: rect(5, 4, 8, 5)).fill()

        eyeColor.setFill()
        NSBezierPath(ovalIn: rect(15, 12.5, 1.4, 1.4)).fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
