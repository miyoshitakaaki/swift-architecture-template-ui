import UIKit

public final class LinkTextView: UITextView {
    public init(style: ViewStyle<LinkTextView>, title: String) {
        super.init(frame: .zero, textContainer: nil)
        self.text = title
        self.apply(style)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
