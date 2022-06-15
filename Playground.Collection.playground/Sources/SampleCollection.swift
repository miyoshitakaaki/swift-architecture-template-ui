import Combine
import OrderedCollections
import UI
import UIKit
import Utility

public final class SampleCollectionViewCell: UICollectionViewCell, CollectionLayout {
    private let label: UILabel = .init(style: .darkGlay97MediumSize, title: "test")

    public struct ViewData: Hashable {
        let text: String
    }

    public var viewData: ViewData? {
        didSet {
            self.label.text = "test"
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.edgeToSelf(self.label)
        self.backgroundColor = .lightGray
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("no need to implement")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 8.0
    }
}

public class SampleCollection: CollectionList {
    public typealias Cell = SampleCollectionViewCell
    public typealias Header = CollectionHeader

    public var emptyView: UIView = UILabel(style: .darkGlay97MediumSize, title: "結果がありません")

    public var topView: UIView? { nil }

    public var topViewHeight: CGFloat { 0 }

    public var hasSegmentedPageContainer: Bool { false }

    public var screenTitle: String { "ランキング" }

    public var backGroundColor: UIColor { .yellow }

    public var topViewSubject = PassthroughSubject<String, Never>()

    public var fetchPublisher: ((parameter: String?, isAdditional: Bool))
        -> AnyPublisher<Items, AppError> {{ _ in
        Just([
            "section1": [
                .init(text: "delivery1"),
                .init(text: "delivery2"),
                .init(text: "delivery3"),
                .init(text: "delivery4"),
                .init(text: "delivery5"),
                .init(text: "delivery6"),
                .init(text: "delivery7"),
                .init(text: "delivery8"),
                .init(text: "delivery9"),
                .init(text: "delivery10"),
                .init(text: "delivery11"),
                .init(text: "delivery12"),
            ],
        ]).setFailureType(to: AppError.self)
            .eraseToAnyPublisher()
    }}

    func mapper(entities: [[String]]) -> OrderedDictionary<String, [Cell.ViewData]> {
        fatalError()
    }

    public var composableLayout: UICollectionViewCompositionalLayout = {
        var compositionalLayoutSectionProvider: (Int, NSCollectionLayoutEnvironment)
            -> NSCollectionLayoutSection? {{ _, _ in
            let itemWidth = UIScreen.main.bounds.width - 32

            let itemLayoutSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(88)
            )

            let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(88)
            )

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )

            group.interItemSpacing = .fixed(0)
            group.contentInsets.leading = 16

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            section.contentInsets.top = 16

            let sectionHeaderSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(0)
            )

            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: sectionHeaderSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )

            section.boundarySupplementaryItems = [sectionHeader]

            return section
        }}

        return UICollectionViewCompositionalLayout(
            sectionProvider: compositionalLayoutSectionProvider
        )

    }()

    public init() {}
}
