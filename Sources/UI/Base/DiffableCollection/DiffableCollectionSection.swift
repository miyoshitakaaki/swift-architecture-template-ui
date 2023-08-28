#if !os(macOS)
import Combine
import UIKit
import Utility

public struct EmptyContent: Hashable {}

public protocol PagingInfoInitializable {
    init(
        initialPagingInfo: [PagingSectionFooterView.InitialPagingInfo],
        pagingInfoSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>,
        pagingControlSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>
    )
}

/// DiffableCollection UI setting protocol
@MainActor
public protocol DiffableCollectionSection: Hashable {
    /// cell registration
    associatedtype CellRegistration: Initializable
    /// header and footer registration
    associatedtype SupplementaryRegistration: PagingInfoInitializable
    /// section data type
    associatedtype Item: Hashable

    /// need pullToRefresh or not
    static var pullToRefreshable: Bool { get }
    /// section contents holder
    static var sections: [Self] { get }
    /// fetch all contents data interval
    static var fetchAllMinuteInterval: Int? { get }
    /// fetch all contents data
    static func reload(fetchRemote: Bool) async -> Result<[Self], AppError>

    /// section header text
    var headerText: String { get }
    /// section header secondary text
    var headerSecondaryText: String { get }

    /// fetch contents for each section
    func fetch(
        fetchRemote: Bool
    ) async -> Result<[Item], AppError>

    /// layout setting for each section
    func layout(
        section: Int,
        environment: NSCollectionLayoutEnvironment,
        items: [Item],
        pagingInfoSubject: PassthroughSubject<PagingSectionFooterView.PagingInfo, Never>
    ) -> NSCollectionLayoutSection

    /// cell setting
    func cellRegistration(
        cellRegistration: CellRegistration,
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: Item
    ) -> UICollectionViewCell?

    /// header and footer settnig
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
#endif
