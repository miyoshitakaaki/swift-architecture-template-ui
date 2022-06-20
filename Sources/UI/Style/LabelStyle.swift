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
}

public extension ViewStyle where T: UILabel {
    static var darkGlay97MediumSize: ViewStyle<T> {
        ViewStyle<T> {
            $0.textColor = UIColor.rgba(97, 97, 97, 1)
            $0.font = UIFont.systemFont(ofSize: 14)
        }
    }
}

public extension ViewStyle where T: UILabel {
    static var lightSmallSize: ViewStyle<T> {
        ViewStyle<T> {
            $0.font = UIFont.systemFont(ofSize: 12)
        }
    }

    static var cornerRadiusBoader: ViewStyle<T> {
        ViewStyle<T> {
            $0.backgroundColor = .white
            $0.layer.borderColor = UIColor.rgba(224, 224, 224, 1).cgColor
            $0.layer.borderWidth = 1.0
            $0.layer.cornerRadius = 8.0
            $0.clipsToBounds = true
        }
    }
}

extension ViewStyle where T: UILabel {
    static var accentBlueBold: ViewStyle<T> {
        ViewStyle<T> {
            $0.textColor = UIConfig.accentBlue
            $0.font = UIFont.boldSystemFont(ofSize: 16)
        }
    }
}

extension ViewStyle where T: UILabel {
    static var darkGlay97SmallSize: ViewStyle<T> {
        ViewStyle<T> {
            $0.textColor = UIConfig.darkGlay97
            $0.font = UIFont.systemFont(ofSize: 12)
        }
    }
}

public extension ViewStyle where T: UILabel {
    static var dangerRedBoldSmallSize: ViewStyle<T> {
        ViewStyle<T> {
            $0.textColor = UIConfig.dangerRed
            $0.font = UIFont.boldSystemFont(ofSize: 12)
        }
    }
}
