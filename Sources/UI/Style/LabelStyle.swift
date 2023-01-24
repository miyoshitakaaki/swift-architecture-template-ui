import UIKit

public extension Stylable where Self == UILabel {
    init(style: ViewStyle<Self>, title: String) {
        self.init()
        self.text = title
        self.apply(style)
    }

    func numberOfLines(_ number: Int) -> Self {
        self.numberOfLines = number
        return self
    }

    func linespace(text: String) {
        var attributes: [NSAttributedString.Key: Any] = [:]
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10.0
        paragraphStyle.alignment = .left
        attributes.updateValue(paragraphStyle, forKey: .paragraphStyle)
        self.attributedText = NSAttributedString(
            string: text,
            attributes: attributes
        )
    }

    func lineBreakMode(_ mode: NSLineBreakMode) -> Self {
        self.lineBreakMode = mode
        return self
    }

    func width(_ value: CGFloat) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalToConstant: value).isActive = true
        return self
    }
}
