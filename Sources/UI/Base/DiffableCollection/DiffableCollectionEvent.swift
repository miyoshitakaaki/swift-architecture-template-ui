import Foundation
import UIKit

public protocol DiffableCollectionEvent: AnyObject {
    func didItemSelected<T>(indexPath: IndexPath, cell: T)
    func didCellDequeud<T>(indexPath: IndexPath, cell: T)
    func didSupplementaryViewDequeued(
        indexPath: IndexPath,
        supplementaryView: UICollectionReusableView?
    )
}
