import UIKit

public final class PaddingLabel: UILabel {
    private let padding: UIEdgeInsets

    private let cornerRadius: CGFloat

    public init(
        frame: CGRect = .zero,
        text: String,
        cornerRadius: CGFloat = 16,
        padding: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
        style: ViewStyle<PaddingLabel>
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        super.init(frame: frame)
        self.text = text
        self.apply(style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func drawText(in rect: CGRect) {
        let newRect = rect.inset(by: self.padding)
        super.drawText(in: newRect)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        self.layer.cornerRadius = self.cornerRadius
        self.clipsToBounds = true
    }

    override public var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height += self.padding.top + self.padding.bottom
        intrinsicContentSize.width += self.padding.left + self.padding.right
        return intrinsicContentSize
    }
}
