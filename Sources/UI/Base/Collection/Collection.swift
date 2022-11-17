import Combine
import UIKit
import Utility

public protocol CollectionList: List, AnalyticsScreenName {
    associatedtype NavContent: NavigationContent
    associatedtype Cell: CollectionLayout
    associatedtype Header: CollectionHeaderLayout
    associatedtype Footer: CollectionFooterLayout
    associatedtype Parameter

    typealias Items = [ListSection<Cell.ViewData, Header.ViewData, Footer.ViewData>]

    var composableLayout: UICollectionViewCompositionalLayout { get }
    var topViewSubject: PassthroughSubject<Parameter, Never> { get }
    var fetchPublisher: ((parameter: Parameter?, isAdditional: Bool))
        -> AnyPublisher<Items, AppError> { get }
    var deletePublisher: (Cell.ViewData) -> AnyPublisher<Void, AppError> { get }
    var floatingButton: UIButton? { get }
    var skeletonItems: Items? { get }
    var titleForItemCount: ((Int) -> String)? { get }
}

public extension CollectionList {
    var floatingButton: UIButton? { nil }
    var topViewSubject: PassthroughSubject<String, Never> { .init() }
    var skeletonItems: Items? { nil }
    var titleForItemCount: ((Int) -> String)? { nil }

    var deletePublisher: (Cell.ViewData) -> AnyPublisher<Void, AppError> {{ _ in
        Just(()).setFailureType(to: AppError.self).eraseToAnyPublisher()
    }}
}

public protocol CollectionLayout: UICollectionViewCell {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
    var delete: ((IndexPath) -> Void)? { get set }
    var indexPath: IndexPath? { get set }
}

public extension CollectionLayout {
    var delete: ((IndexPath) -> Void)? {
        get { nil }
        set {}
    }

    var indexPath: IndexPath? {
        get { nil }
        set {}
    }
}

public protocol CollectionHeaderLayout: UICollectionReusableView {
    associatedtype ViewData: Equatable & Hashable
    func updateHeader(data: ViewData)
}

public protocol CollectionFooterLayout: UICollectionReusableView {
    associatedtype ViewData: Equatable & Hashable
    func updateFooter(data: ViewData)
}
