import Combine
import OrderedCollections
import UIKit
import Utility

public protocol CollectionList: List {
    associatedtype Cell: CollectionLayout
    associatedtype Header: CollectionHeaderLayout
    associatedtype Parameter

    typealias Items = OrderedDictionary<String, [Cell.ViewData]>

    var screenTitle: String { get }
    var composableLayout: UICollectionViewCompositionalLayout { get }
    var topViewSubject: PassthroughSubject<Parameter, Never> { get }
    var fetchPublisher: ((parameter: Parameter?, isAdditional: Bool))
        -> AnyPublisher<Items, AppError> { get }

    var floatingButton: UIButton? { get }
}

public extension CollectionList {
    var floatingButton: UIButton? { nil }
}

public protocol CollectionLayout: UICollectionViewCell {
    associatedtype ViewData: Hashable
    var viewData: ViewData? { get set }
}

public protocol CollectionHeaderLayout: UICollectionReusableView {
    func updateHeader(text: String)
}
