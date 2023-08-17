#if !os(macOS)
import Foundation
import UIKit
import Utility

@MainActor
public protocol DiffableCollectionEvent: AnyObject {
    func didItemSelected<T>(indexPath: IndexPath, cell: T)
    func didErrorOccured(error: AppError)
}
#endif
