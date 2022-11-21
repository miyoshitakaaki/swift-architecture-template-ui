import UIKit

public final class CheckMarkButton: UIButton {
    public var checkFlag = false

    public var onBackGroundColor = UIColor.rgba(17, 76, 190, 1)
    public var onCheckMarkColor: UIColor = .white
    public var offBackGroundColor: UIColor = .white
    public var offCheckMarkColor: UIColor = .white

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        if self.checkFlag {
            drawCheckMark(
                rect,
                markColor: self.onCheckMarkColor,
                backGroundColor: self.onBackGroundColor
            )
        } else {
            drawCheckMark(
                rect,
                markColor: self.offCheckMarkColor,
                backGroundColor: self.offBackGroundColor
            )
        }
    }

    public func toggle() {
        self.checkFlag.toggle()
        setNeedsDisplay()
    }
}

private extension CheckMarkButton {
    func drawCheckMark(_ rect: CGRect, markColor: UIColor, backGroundColor: UIColor) {
        let xCenter: CGFloat = rect.width / 2
        let yCenter: CGFloat = rect.height / 2
        let circle = UIBezierPath(
            arcCenter: CGPoint(x: xCenter, y: yCenter),
            radius: 12,
            startAngle: 0,
            endAngle: CGFloat(Double.pi) * 2,
            clockwise: true
        )
        backGroundColor.setFill()
        circle.fill()
        let path = UIBezierPath()

        path.move(to: CGPoint(x: xCenter - 5, y: yCenter))
        path.addLine(to: CGPoint(x: xCenter - 2, y: yCenter + 3.1))
        path.addLine(to: CGPoint(x: xCenter + 5, y: yCenter - 3.1))
        path.lineWidth = 2.0
        markColor.setStroke()
        path.stroke()
    }
}
