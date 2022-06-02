import Foundation
import UIKit

public struct ViewStyle<T> {
    let style: (T) -> Void

    public init(style: @escaping (T) -> Void) {
        self.style = style
    }
}

public extension ViewStyle {
    func compose(with style: ViewStyle<T>) -> ViewStyle<T> {
        ViewStyle<T> {
            self.style($0)
            style.style($0)
        }
    }
}

public protocol Stylable {
    init()
}

extension UIView: Stylable {}

public extension Stylable {
    init(style: ViewStyle<Self>) {
        self.init()
        self.apply(style)
    }

    func apply(_ style: ViewStyle<Self>) {
        style.style(self)
    }
}
