import Foundation

struct Shortcut: Codable {
    let keyBinding: String
    let action: WindowAction

    enum CodingKeys: String, CodingKey {
        case keyBinding = "shortcut_key_binding"
        case action = "shortcut_name"
    }
}

enum WindowAction: String, Codable, CaseIterable {
    case redoLastMove = "RedoLastMove"
    case makeSmaller = "MakeSmaller"
    case moveToPreviousThird = "MoveToPreviousThird"
    case moveToUpperRight = "MoveToUpperRight"
    case moveToBottomHalf = "MoveToBottomHalf"
    case moveToNextDisplay = "MoveToNextDisplay"
    case moveToTopHalf = "MoveToTopHalf"
    case moveToLowerLeft = "MoveToLowerLeft"
    case makeLarger = "MakeLarger"
    case undoLastMove = "UndoLastMove"
    case moveToPreviousDisplay = "MoveToPreviousDisplay"
    case moveToFullscreen = "MoveToFullscreen"
    case moveToNextThird = "MoveToNextThird"
    case moveToLeftHalf = "MoveToLeftHalf"
    case moveToCenter = "MoveToCenter"
    case moveToRightHalf = "MoveToRightHalf"
    case moveToLowerRight = "MoveToLowerRight"
    case moveToUpperLeft = "MoveToUpperLeft"

    var displayName: String {
        switch self {
        case .redoLastMove: return "Redo Last Move"
        case .makeSmaller: return "Make Smaller"
        case .moveToPreviousThird: return "Previous Third"
        case .moveToUpperRight: return "Upper Right"
        case .moveToBottomHalf: return "Bottom Half"
        case .moveToNextDisplay: return "Next Display"
        case .moveToTopHalf: return "Top Half"
        case .moveToLowerLeft: return "Lower Left"
        case .makeLarger: return "Make Larger"
        case .undoLastMove: return "Undo Last Move"
        case .moveToPreviousDisplay: return "Previous Display"
        case .moveToFullscreen: return "Fullscreen"
        case .moveToNextThird: return "Next Third"
        case .moveToLeftHalf: return "Left Half"
        case .moveToCenter: return "Center"
        case .moveToRightHalf: return "Right Half"
        case .moveToLowerRight: return "Lower Right"
        case .moveToUpperLeft: return "Upper Left"
        }
    }
}
