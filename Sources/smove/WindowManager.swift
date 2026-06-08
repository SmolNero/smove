import AppKit
import ApplicationServices

final class WindowManager {
    private struct MoveRecord {
        let window: AXUIElement
        let frame: CGRect
    }

    private var undoStack: [MoveRecord] = []
    private var redoStack: [MoveRecord] = []

    func perform(_ action: WindowAction) {
        switch action {
        case .undoLastMove:
            undoLastMove()
        case .redoLastMove:
            redoLastMove()
        default:
            moveFocusedWindow(action)
        }
    }

    private func moveFocusedWindow(_ action: WindowAction) {
        guard let window = focusedWindow(),
              let currentFrame = frame(of: window),
              let currentScreen = screen(for: currentFrame),
              let targetFrame = targetFrame(for: action, currentFrame: currentFrame, currentScreen: currentScreen) else {
            return
        }

        let roundedTarget = targetFrame.roundedForWindow
        guard !currentFrame.isNearlyEqual(to: roundedTarget) else { return }

        undoStack.append(MoveRecord(window: window, frame: currentFrame))
        redoStack.removeAll()
        setFrame(roundedTarget, for: window)
    }

    private func undoLastMove() {
        guard let record = undoStack.popLast(), let currentFrame = frame(of: record.window) else {
            return
        }

        redoStack.append(MoveRecord(window: record.window, frame: currentFrame))
        setFrame(record.frame, for: record.window)
    }

    private func redoLastMove() {
        guard let record = redoStack.popLast(), let currentFrame = frame(of: record.window) else {
            return
        }

        undoStack.append(MoveRecord(window: record.window, frame: currentFrame))
        setFrame(record.frame, for: record.window)
    }

    private func targetFrame(for action: WindowAction, currentFrame: CGRect, currentScreen: NSScreen) -> CGRect? {
        let visible = currentScreen.visibleFrame
        let halfWidth = visible.width / 2
        let halfHeight = visible.height / 2

        switch action {
        case .moveToLeftHalf:
            return CGRect(x: visible.minX, y: visible.minY, width: halfWidth, height: visible.height)
        case .moveToRightHalf:
            return CGRect(x: visible.midX, y: visible.minY, width: halfWidth, height: visible.height)
        case .moveToTopHalf:
            return CGRect(x: visible.minX, y: visible.midY, width: visible.width, height: halfHeight)
        case .moveToBottomHalf:
            return CGRect(x: visible.minX, y: visible.minY, width: visible.width, height: halfHeight)
        case .moveToUpperLeft:
            return CGRect(x: visible.minX, y: visible.midY, width: halfWidth, height: halfHeight)
        case .moveToUpperRight:
            return CGRect(x: visible.midX, y: visible.midY, width: halfWidth, height: halfHeight)
        case .moveToLowerLeft:
            return CGRect(x: visible.minX, y: visible.minY, width: halfWidth, height: halfHeight)
        case .moveToLowerRight:
            return CGRect(x: visible.midX, y: visible.minY, width: halfWidth, height: halfHeight)
        case .moveToFullscreen:
            return visible
        case .moveToCenter:
            let width = min(currentFrame.width, visible.width)
            let height = min(currentFrame.height, visible.height)
            return CGRect(
                x: visible.midX - width / 2,
                y: visible.midY - height / 2,
                width: width,
                height: height
            ).clamped(to: visible)
        case .moveToNextThird:
            return thirdFrame(direction: 1, currentFrame: currentFrame, visibleFrame: visible)
        case .moveToPreviousThird:
            return thirdFrame(direction: -1, currentFrame: currentFrame, visibleFrame: visible)
        case .moveToNextDisplay:
            return displayFrame(direction: 1, currentFrame: currentFrame, currentScreen: currentScreen)
        case .moveToPreviousDisplay:
            return displayFrame(direction: -1, currentFrame: currentFrame, currentScreen: currentScreen)
        case .makeLarger:
            let stepX = max(32, visible.width / 16)
            let stepY = max(24, visible.height / 16)
            return currentFrame.insetBy(dx: -stepX, dy: -stepY).clamped(to: visible)
        case .makeSmaller:
            let stepX = max(32, visible.width / 16)
            let stepY = max(24, visible.height / 16)
            let minWidth = min(320, visible.width)
            let minHeight = min(220, visible.height)
            let width = max(minWidth, currentFrame.width - stepX * 2)
            let height = max(minHeight, currentFrame.height - stepY * 2)
            return CGRect(
                x: currentFrame.midX - width / 2,
                y: currentFrame.midY - height / 2,
                width: width,
                height: height
            ).clamped(to: visible)
        case .undoLastMove, .redoLastMove:
            return nil
        }
    }

    private func thirdFrame(direction: Int, currentFrame: CGRect, visibleFrame: CGRect) -> CGRect {
        let thirdWidth = visibleFrame.width / 3
        let currentIndex = closestThirdIndex(currentFrame: currentFrame, visibleFrame: visibleFrame)
        let nextIndex = (currentIndex + direction + 3) % 3

        return CGRect(
            x: visibleFrame.minX + CGFloat(nextIndex) * thirdWidth,
            y: visibleFrame.minY,
            width: thirdWidth,
            height: visibleFrame.height
        )
    }

    private func closestThirdIndex(currentFrame: CGRect, visibleFrame: CGRect) -> Int {
        let thirdWidth = visibleFrame.width / 3
        guard thirdWidth > 0 else { return 0 }

        let centerOffset = (currentFrame.midX - visibleFrame.minX) / thirdWidth
        return min(2, max(0, Int(centerOffset.rounded(.down))))
    }

    private func displayFrame(direction: Int, currentFrame: CGRect, currentScreen: NSScreen) -> CGRect? {
        let screens = NSScreen.screens.sorted { lhs, rhs in
            if lhs.frame.minX == rhs.frame.minX {
                return lhs.frame.minY < rhs.frame.minY
            }

            return lhs.frame.minX < rhs.frame.minX
        }

        guard screens.count > 1,
              let currentIndex = screens.firstIndex(where: { $0 === currentScreen }) else {
            return nil
        }

        let destinationIndex = (currentIndex + direction + screens.count) % screens.count
        let sourceVisible = currentScreen.visibleFrame
        let destinationVisible = screens[destinationIndex].visibleFrame

        let relativeX = ratio(currentFrame.minX - sourceVisible.minX, sourceVisible.width)
        let relativeY = ratio(currentFrame.minY - sourceVisible.minY, sourceVisible.height)
        let relativeWidth = ratio(currentFrame.width, sourceVisible.width)
        let relativeHeight = ratio(currentFrame.height, sourceVisible.height)

        let target = CGRect(
            x: destinationVisible.minX + relativeX * destinationVisible.width,
            y: destinationVisible.minY + relativeY * destinationVisible.height,
            width: max(120, relativeWidth * destinationVisible.width),
            height: max(80, relativeHeight * destinationVisible.height)
        )

        return target.clamped(to: destinationVisible)
    }

    private func ratio(_ value: CGFloat, _ divisor: CGFloat) -> CGFloat {
        guard divisor != 0 else { return 0 }
        return value / divisor
    }

    private func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?

        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
           let window = value {
            return (window as! AXUIElement)
        }

        if AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &value) == .success,
           let window = value {
            return (window as! AXUIElement)
        }

        return nil
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        guard let position = pointAttribute(kAXPositionAttribute, of: window),
              let size = sizeAttribute(kAXSizeAttribute, of: window) else {
            return nil
        }

        return axToAppKit(CGRect(origin: position, size: size))
    }

    private func setFrame(_ frame: CGRect, for window: AXUIElement) {
        let axFrame = appKitToAX(frame.roundedForWindow)
        var position = axFrame.origin
        var size = axFrame.size

        guard let positionValue = AXValueCreate(.cgPoint, &position),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return
        }

        _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        _ = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    }

    private func pointAttribute(_ attribute: String, of window: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, attribute as CFString, &value) == .success,
              let value else {
            return nil
        }

        let axValue = value as! AXValue
        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func sizeAttribute(_ attribute: String, of window: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, attribute as CFString, &value) == .success,
              let value else {
            return nil
        }

        let axValue = value as! AXValue
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
        return size
    }

    private func screen(for frame: CGRect) -> NSScreen? {
        let center = CGPoint(x: frame.midX, y: frame.midY)

        if let containing = NSScreen.screens.first(where: { $0.frame.contains(center) }) {
            return containing
        }

        return NSScreen.screens.max { lhs, rhs in
            intersectionArea(lhs.frame, frame) < intersectionArea(rhs.frame, frame)
        }
    }

    private func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else { return 0 }
        return intersection.width * intersection.height
    }

    private func appKitToAX(_ rect: CGRect) -> CGRect {
        let referenceMaxY = coordinateReferenceMaxY
        return CGRect(
            x: rect.minX,
            y: referenceMaxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    private func axToAppKit(_ rect: CGRect) -> CGRect {
        let referenceMaxY = coordinateReferenceMaxY
        return CGRect(
            x: rect.minX,
            y: referenceMaxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    private var coordinateReferenceMaxY: CGFloat {
        NSScreen.screens.first?.frame.maxY ?? 0
    }
}

private extension CGRect {
    var roundedForWindow: CGRect {
        CGRect(
            x: round(minX),
            y: round(minY),
            width: max(1, round(width)),
            height: max(1, round(height))
        )
    }

    func clamped(to bounds: CGRect) -> CGRect {
        var rect = self

        rect.size.width = min(rect.width, bounds.width)
        rect.size.height = min(rect.height, bounds.height)

        if rect.minX < bounds.minX {
            rect.origin.x = bounds.minX
        }

        if rect.maxX > bounds.maxX {
            rect.origin.x = bounds.maxX - rect.width
        }

        if rect.minY < bounds.minY {
            rect.origin.y = bounds.minY
        }

        if rect.maxY > bounds.maxY {
            rect.origin.y = bounds.maxY - rect.height
        }

        return rect
    }

    func isNearlyEqual(to other: CGRect) -> Bool {
        abs(minX - other.minX) < 1 &&
            abs(minY - other.minY) < 1 &&
            abs(width - other.width) < 1 &&
            abs(height - other.height) < 1
    }
}
