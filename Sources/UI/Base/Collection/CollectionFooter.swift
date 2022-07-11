import Foundation
import UIKit

open class CollectionFooter: UICollectionReusableView, CollectionFooterLayout {
    public let titleLabel: UILabel = .init()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = .lightGray
        self.titleLabel.text = "test"

        addSubviews(
            self.titleLabel,
            constraints:
            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16)
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
