import UIKit

public class DottedLineView: UIView {
    override public func draw(_ rect: CGRect) {
        let dotted = UIBezierPath()
        dotted.lineWidth = 1
        dotted.lineCapStyle = .butt
        dotted.move(to: CGPoint(x: 0, y: 1))
        dotted.addLine(to: CGPoint(x: self.frame.size.width, y: 1))
        dotted.setLineDash([2, 2], count: [2, 2].count, phase: 0)
        UIConfig.darkGray_400.setStroke()
        dotted.stroke()
    }
}
