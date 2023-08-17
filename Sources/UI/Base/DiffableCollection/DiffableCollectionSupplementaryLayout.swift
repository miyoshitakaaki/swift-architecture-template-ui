#if !os(macOS)
import UIKit

@MainActor
public protocol DiffableCollectionSupplementaryLayout: UICollectionReusableView {
    associatedtype ViewData
    var viewData: ViewData? { get set }
    var indexPath: IndexPath? { get set }
}
#endif
