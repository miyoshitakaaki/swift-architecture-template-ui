import UIKit

public extension Stylable where Self == UIView {
    init(style: ViewStyle<Self>) {
        self.init()
        self.apply(style)
    }

    init(style: ViewStyle<Self>, height: CGFloat) {
        self.init()
        self.apply(style)
        self.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
