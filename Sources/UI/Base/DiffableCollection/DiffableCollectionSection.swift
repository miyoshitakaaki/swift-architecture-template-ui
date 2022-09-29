import Combine
import UIKit
import Utility

public struct EmptyContent: Hashable {}

public protocol DiffableCollectionSection: Hashable {
    associatedtype CellRegistration
    associatedtype SupplementaryRegistration
    associatedtype Item: Hashable

    var headerText: String { get }
    var headerSecondaryText: String { get }
    var fetch: AnyPublisher<[Item], AppError> { get }

    static var pullToRefreshable: Bool { get }
    static var sections: [Self] { get }
    static var fetchAll: AnyPublisher<[Self], AppError> { get }

    func layout(section: Int, environment: NSCollectionLayoutEnvironment)
        -> NSCollectionLayoutSection

    func cellRegistration(
        cellRegistration: CellRegistration,
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: Item
    ) -> UICollectionViewCell?

    func supplementaryRegistration(
        collectionView: UICollectionView,
        kind: String,
        supplementaryRegistration: SupplementaryRegistration,
        indexPath: IndexPath
    ) -> UICollectionReusableView?
}

public extension DiffableCollectionSection {
    static var pullToRefreshable: Bool { false }
}
