import Combine
import UIKit
import Utility

public struct EmptyContent: Hashable {}

public protocol PagingInfoInitializable {
    init(
        initialPagingInfo: [PagingSectionFooterView.InitialPagingInfo],
        pagingInfoSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>
    )
}

@MainActor
public protocol DiffableCollectionSection: Hashable {
    associatedtype CellRegistration: Initializable
    associatedtype SupplementaryRegistration: PagingInfoInitializable
    associatedtype Item: Hashable

    static var pullToRefreshable: Bool { get }
    static var sections: [Self] { get }
    static var fetchAllMinuteInterval: Int? { get }
    static func reload(fetchRemote: Bool) async -> Result<[Self], AppError>

    var headerText: String { get }
    var headerSecondaryText: String { get }

    func fetch(
        fetchRemote: Bool
    ) async -> Result<[Item], AppError>

    func layout(
        section: Int,
        environment: NSCollectionLayoutEnvironment,
        items: [Item],
        pagingInfoSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>
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
    static var fetchAllMinuteInterval: Int? { nil }
}
