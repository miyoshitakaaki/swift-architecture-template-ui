#if !os(macOS)
import UIKit

public extension UIScrollView {
    enum ScrollDirection {
        case top
        case bottom
        case left
        case right
    }

    func scroll(to direction: ScrollDirection, animated: Bool) {
        let offset: CGPoint
        switch direction {
        case .top:
            offset = CGPoint(x: contentOffset.x, y: -contentInset.top)
        case .bottom:
            offset = CGPoint(
                x: contentOffset.x,
                y: max(-contentInset.top, contentSize.height - frame.height + contentInset.bottom)
            )
        case .left:
            offset = CGPoint(x: -contentInset.left, y: contentOffset.y)
        case .right:
            offset = CGPoint(
                x: max(-contentInset.left, contentSize.width - frame.width + contentInset.right),
                y: contentOffset.y
            )
        }
        setContentOffset(offset, animated: animated)
    }
}
#endif
