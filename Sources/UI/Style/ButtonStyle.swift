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
