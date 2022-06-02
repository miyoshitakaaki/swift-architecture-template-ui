import UIKit

public final class UnderArrowView: UIView {
    private let arrowColor: UIColor

    public init() {
        self.arrowColor = UIColor.rgba(97, 97, 97, 1)
        super.init(frame: .zero)
        self.backgroundColor = .white
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("no need to implement")
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        self.isUserInteractionEnabled = false
        let path = UIBezierPath()
        let xCenter: CGFloat = rect.width / 2
        let yCenter: CGFloat = rect.height / 2

        path.move(to: CGPoint(x: xCenter - 7, y: yCenter - 3.5))
        path.addLine(to: CGPoint(x: xCenter, y: yCenter + 3.5))
        path.addLine(to: CGPoint(x: xCenter + 7, y: yCenter - 3.5))
        path.lineWidth = 1.0
        self.arrowColor.setStroke()
        path.stroke()
    }
}
