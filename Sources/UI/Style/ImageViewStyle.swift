#if !os(macOS)
import UIKit

public extension Stylable where Self == UIImageView {
    init(style: ViewStyle<Self>) {
        self.init()
        self.apply(style)
    }
}
#endif
