import Foundation
import UIKit
import Utility

public protocol DiffableCollectionEvent: FlowController {
    func didItemSelected<T>(indexPath: IndexPath, cell: T)
    func didSupplementaryViewDequeued(
        indexPath: IndexPath,
        supplementaryView: UICollectionReusableView?
    )
    func didErrorOccured(error: AppError)
}

public extension DiffableCollectionEvent where T == NavigationController {
    func didErrorOccured(error: AppError) {
        self.show(error: error)
    }
}

public extension DiffableCollectionEvent where T == TabBarController {
    func didErrorOccured(error: AppError) {
        self.show(error: error)
    }
}
