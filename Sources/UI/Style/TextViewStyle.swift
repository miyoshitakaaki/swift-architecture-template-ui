import UIKit

public extension Stylable where Self == UITextView {
    init(style: ViewStyle<Self>) {
        self.init()
        self.apply(style)
    }

    init(style: ViewStyle<Self>, title: String) {
        self.init()
        self.text = title
        self.apply(style)
    }
}
