import Foundation
import UIKit
import Utility

public protocol DiffableCollectionEvent: AnyObject {
    func didItemSelected<T>(indexPath: IndexPath, cell: T)
    func didCellDequeud<T>(indexPath: IndexPath, cell: T)
    func didSupplementaryViewDequeued(
        indexPath: IndexPath,
        supplementaryView: UICollectionReusableView?
    )
    func didErrorOccured(error: AppError)
}
