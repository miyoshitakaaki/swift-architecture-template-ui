import UIKit

public final class BadgeSegmentedControl: UISegmentedControl, SegmentedControl {
    private var badgeViewLeft: UIView = .init(frame: .zero)
    private var badgeViewRight: UIView = .init(frame: .zero)

    override public init(items: [Any]?) {
        super.init(items: items)

        self.backgroundColor = UIColor.rgba(238, 238, 238, 1)
        self.selectedSegmentTintColor = UIColor.white

        self.setTitleTextAttributes(
            [
                NSAttributedString.Key.foregroundColor: UIColor.rgba(33, 33, 33, 1),
                .font: UIFont.boldSystemFont(ofSize: 13),
            ],
            for: .normal
        )

        self.setTitleTextAttributes(
            [
                NSAttributedString.Key.foregroundColor: UIColor.rgba(17, 76, 190, 1),
                .font: UIFont.boldSystemFont(ofSize: 13),
            ],
            for: .selected
        )

        self.badgeViewLeft.backgroundColor = .red
        self.badgeViewRight.backgroundColor = .red

        self.badgeViewLeft.layer.cornerRadius = 4
        self.badgeViewRight.layer.cornerRadius = 4

        self.addSubview(self.badgeViewLeft)
        self.addSubview(self.badgeViewRight)

        self.badgeViewLeft.isHidden = true
        self.badgeViewRight.isHidden = true
    }

    // TODO: iOS13はこれがないとクラッシュする。iOS13を切ったら削除すること！
    @available(iOS, obsoleted: 14.0, unavailable)
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        self.badgeViewRight.frame = .init(x: self.frame.width - 16, y: 10, width: 8, height: 8)
        self.badgeViewLeft.frame = .init(x: self.frame.width / 2 - 16, y: 10, width: 8, height: 8)
    }

    public func showBadge(show: Bool, index: Int, number: Int?) {
        if index == 0 {
            self.badgeViewLeft.isHidden = !show
        } else if index == 1 {
            self.badgeViewRight.isHidden = !show
        }
    }
}
