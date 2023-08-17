#if !os(macOS)
import UIKit

public final class FormSectionLabel: UILabel {
    public let padding: UIEdgeInsets

    public init(title: String, leftInset: CGFloat = 0) {
        self.padding = .init(top: 40, left: leftInset, bottom: 16, right: 0)
        super.init(frame: .zero)
        apply(.init {
            $0.textColor = UIColor.rgba(17, 76, 190, 1)
            $0.font = UIFont.boldSystemFont(ofSize: 16)
        })
        self.text = title
    }

    public init(title: String, subTitle: String, leftInset: CGFloat = 0) {
        self.padding = .init(top: 40, left: leftInset, bottom: 16, right: 0)
        super.init(frame: .zero)
        attributes(title: title, subTitle: subTitle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override public func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: self.padding))
    }

    override public var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height += self.padding.top + self.padding.bottom
        intrinsicContentSize.width += self.padding.left + self.padding.right
        return intrinsicContentSize
    }
}

private extension FormSectionLabel {
    func attributes(title: String, subTitle: String) {
        self.numberOfLines = 2
        let text: String
        if title.isEmpty {
            text = subTitle
        } else {
            text = title + "\n" + subTitle
        }
        var stringAttributes: [NSAttributedString.Key: Any] = [:]
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5.0
        stringAttributes.updateValue(paragraphStyle, forKey: .paragraphStyle)
        let attributedString = NSMutableAttributedString(string: text, attributes: stringAttributes)
        let titleTextRange = NSString(string: text).range(of: title)
        attributedString.addAttributes(
            [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.rgba(97, 97, 97, 1),
            ],
            range: titleTextRange
        )
        let subTitleTextRange = NSString(string: text).range(of: subTitle)
        attributedString.addAttributes(
            [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.rgba(33, 33, 33, 1),
            ],
            range: subTitleTextRange
        )
        self.attributedText = attributedString
    }
}
#endif
