import Combine
import UIKit
import Utility

public protocol CollectionList: List {
    associatedtype NavContent: NavigationContent
    associatedtype Cell: CollectionLayout
    associatedtype Header: CollectionHeaderLayout
    associatedtype Footer: CollectionFooterLayout
    associatedtype Parameter

    typealias Items = [ListSection<Cell.ViewData, Header.ViewData>]

    var hideTabbar: Bool { get }
    var composableLayout: UICollectionViewCompositionalLayout { get }
    var topViewSubject: PassthroughSubject<Parameter, Never> { get }
    var fetchPublisher: ((parameter: Parameter?, isAdditional: Bool))
        -> AnyPublisher<Items, AppError> { get }
    var floatingButton: UIButton? { get }
}

public extension CollectionList {
    var floatingButton: UIButton? { nil }
    var hideTabbar: Bool { false }
    var topViewSubject: PassthroughSubject<String, Never> { .init() }
}

public protocol CollectionLayout: UICollectionViewCell {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
    var delete: ((IndexPath) -> Void)? { get set }
}

public extension CollectionLayout {
    var delete: ((IndexPath) -> Void)? {
        get { nil }
        set {}
    }
}

public protocol CollectionHeaderLayout: UICollectionReusableView {
    associatedtype ViewData: Equatable & Hashable
    func updateHeader(data: ViewData)
}

public protocol CollectionFooterLayout: UICollectionReusableView {}
