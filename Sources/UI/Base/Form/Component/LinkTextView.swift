import UIKit

public final class LinkTextView: UITextView {
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard
            let position = closestPosition(to: point),
            let range = tokenizer.rangeEnclosingPosition(
                position,
                with: .character,
                inDirection: UITextDirection(rawValue: UITextLayoutDirection.left.rawValue)
            )
        else {
            return false
        }
        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }

    override public func becomeFirstResponder() -> Bool {
        false
    }
}
