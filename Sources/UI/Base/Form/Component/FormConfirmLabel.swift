#if !os(macOS)
import UIKit

public final class FormConfirmLabel: UILabel {
    public let padding: UIEdgeInsets

    public init(title: String, leftInset: CGFloat = 0) {
        self.padding = .init(top: 8, left: leftInset, bottom: 24, right: 32)
        super.init(frame: .zero)
        apply(.init {
            $0.textColor = UIColor.rgba(97, 97, 97, 1)
            $0.font = UIFont.systemFont(ofSize: 14)
        })
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
}
#endif
