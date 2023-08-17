#if !os(macOS)
import UIKit

public final class RefreshControl: UIRefreshControl {
    private let moveY: CGFloat

    public init(moveY: CGFloat) {
        self.moveY = moveY
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        var frame: CGRect = self.frame
        frame.origin.y = frame.origin.y + self.moveY
        self.frame = frame
    }
}
#endif
