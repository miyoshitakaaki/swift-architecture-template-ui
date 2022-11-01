import Combine
import UIKit
import Utility

public struct EmptyContent: Hashable {}

public protocol DiffableCollectionSection: Hashable {
    associatedtype CellRegistration
    associatedtype SupplementaryRegistration
    associatedtype Item: Hashable

    static var pullToRefreshable: Bool { get }
    static var sections: [Self] { get }
    static func reload(fetchRemote: Bool) -> AnyPublisher<[Self], AppError>

    var headerText: String { get }
    var headerSecondaryText: String { get }

    func fetch(
        fetchRemote: Bool
    ) -> AnyPublisher<[Item], AppError>

    func layout(
        section: Int,
        environment: NSCollectionLayoutEnvironment,
        items: [Item]
    ) -> NSCollectionLayoutSection

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
