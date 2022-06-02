import Foundation
import UIKit

public class CollectionViewCell: UICollectionViewCell {
    private let label: UILabel = .init()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .lightGray

        self.label.text = "テスト"

        addSubviews(
            self.label,
            constraints:
            self.label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("no need to implement")
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        layer.cornerRadius = 8
        clipsToBounds = true
    }
}
