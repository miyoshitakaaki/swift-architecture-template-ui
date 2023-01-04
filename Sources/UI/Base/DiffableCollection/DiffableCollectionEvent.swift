import Foundation
import UIKit
import Utility

@MainActor
public protocol DiffableCollectionEvent: FlowController {
    func didItemSelected<T>(indexPath: IndexPath, cell: T)
    func didErrorOccured(error: AppError)
}

public extension DiffableCollectionEvent where T == NavigationController {
    @MainActor
    func didErrorOccured(error: AppError) {
        self.show(error: error)
    }
}

public extension DiffableCollectionEvent where T == TabBarController {
    func didErrorOccured(error: AppError) {
        self.show(error: error)
    }
}
