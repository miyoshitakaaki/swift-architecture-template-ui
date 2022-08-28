import UIKit

public protocol DiffableCollectionContent {
    var rightNavigationItems: [UIBarButtonItem] { get }
    var leftNavigationItems: [UIBarButtonItem] { get }
    var title: String? { get }
    var leftBarButtonItemTintColor: UIColor { get }
}
