import UIKit

public extension Stylable where Self: UIButton {
    init(style: ViewStyle<Self>, title: String, for state: UIControl.State = .normal) {
        self.init()
        self.setTitle(title, for: state)
        self.apply(style)
    }

    init(image: UIImage?) {
        self.init()
        self.setImage(image, for: .normal)
    }
}

extension ViewStyle where T: UIButton {
    static var darkGray600: ViewStyle<T> {
        ViewStyle<T> {
            $0.setTitleColor(UIConfig.darkGray_600, for: .normal)
        }
    }

    static var backgroundAccentBlue: ViewStyle<T> {
        ViewStyle<T> {
            $0.backgroundColor = UIConfig.accentBlue
        }
    }

    public static var backgroundDarkGray: ViewStyle<T> {
        ViewStyle<T> {
            $0.backgroundColor = UIConfig.darkGray
        }
    }
}

extension ViewStyle where T: UIButton {
    static var accentBlue: ViewStyle<T> {
        ViewStyle<T> {
            $0.setTitleColor(UIConfig.accentBlue, for: .normal)
        }
    }
}
