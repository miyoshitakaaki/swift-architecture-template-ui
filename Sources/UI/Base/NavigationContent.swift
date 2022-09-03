import UIKit

public protocol NavigationContent {
    var rightNavigationItems: [UIBarButtonItem] { get }
    var leftNavigationItems: [UIBarButtonItem] { get }
    var title: String? { get }
    var leftBarButtonItemTintColor: UIColor { get }
}
