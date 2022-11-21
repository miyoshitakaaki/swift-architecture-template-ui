import UIKit

public class LeftArrowView: UIView {
    public var color = UIColor.rgba(17, 76, 190, 1) {
        didSet {
            setNeedsDisplay()
        }
    }

    override public func draw(_ rect: CGRect) {
        let arrow = UIBezierPath()
        arrow.lineWidth = 1
        arrow.move(to: CGPoint(x: rect.width, y: 0))
        arrow.addLine(to: CGPoint(x: 0, y: rect.height / 2))
        arrow.addLine(to: CGPoint(x: rect.width, y: rect.height))
        UIColor.rgba(17, 76, 190, 1).setStroke()
        arrow.stroke()
    }
}
