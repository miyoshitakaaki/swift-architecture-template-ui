import UIKit

public extension Stylable where Self == UIStackView {
    init(style: ViewStyle<Self>, view: [UIView]) {
        self.init()
        self.apply(style)
        view.forEach(self.addArrangedSubview)
    }
}
