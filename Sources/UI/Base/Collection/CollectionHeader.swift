import Foundation
import UIKit

open class CollectionHeader: UICollectionReusableView, CollectionHeaderLayout {
    public let titleLabel: UILabel = .init()

    public func updateHeader(data: String) {
        self.titleLabel.text = data
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

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
