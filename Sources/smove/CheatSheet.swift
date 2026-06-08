import Foundation

extension Array where Element == Shortcut {
    func sortedByCheatSheetOrder() -> [Shortcut] {
        let order: [WindowAction] = [
            .moveToLeftHalf,
            .moveToRightHalf,
            .moveToTopHalf,
            .moveToBottomHalf,
            .moveToFullscreen,
            .moveToCenter,
            .moveToUpperLeft,
            .moveToUpperRight,
            .moveToLowerLeft,
            .moveToLowerRight,
            .moveToNextThird,
            .moveToPreviousThird,
            .makeLarger,
            .makeSmaller,
            .moveToNextDisplay,
            .moveToPreviousDisplay,
            .undoLastMove,
            .redoLastMove
        ]

        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })

        return sorted {
            let lhsRank = rank[$0.action] ?? Int.max
            let rhsRank = rank[$1.action] ?? Int.max

            if lhsRank == rhsRank {
                return $0.action.displayName < $1.action.displayName
            }

            return lhsRank < rhsRank
        }
    }
}
