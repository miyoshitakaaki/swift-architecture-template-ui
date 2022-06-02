import UIKit

public class NoticeLabel: UILabel {
    private let insets = UIEdgeInsets(top: 10, left: 15, bottom: 11, right: 15)

    public init(text: String) {
        super.init(frame: .zero)
        self.text = text
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: self.insets))
    }

    override open var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.width += (insets.left + insets.right)
        intrinsicContentSize.height += (insets.top + insets.bottom)
        return intrinsicContentSize
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        self.backgroundColor = .white
        self.layer.borderColor = UIColor.rgba(244, 244, 244, 1).cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 3.0
        self.clipsToBounds = true
        self.numberOfLines = 0
    }
}
