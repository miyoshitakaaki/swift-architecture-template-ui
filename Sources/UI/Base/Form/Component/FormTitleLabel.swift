import UIKit

public final class FormTitleLabel: UILabel {
    public let padding: UIEdgeInsets

    public init(
        title: String,
        leftInset: CGFloat = 8,
        titleColor: UIColor = UIColor.rgba(97, 97, 97, 1)
    ) {
        self.padding = .init(top: 24, left: leftInset, bottom: 8, right: 0)
        super.init(frame: .zero)
        self.textColor = titleColor
        self.font = UIFont.boldSystemFont(ofSize: 12)
        self.text = title
        self.numberOfLines = 0
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

    override public var isEnabled: Bool {
        didSet {
            self.textColor = self.isEnabled
                ? UIColor.rgba(97, 97, 97, 1)
                : UIColor.rgba(238, 238, 238, 1)
        }
    }
}
