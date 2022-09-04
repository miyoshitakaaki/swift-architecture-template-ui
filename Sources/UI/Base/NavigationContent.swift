import UIKit

public protocol NavigationContent {
    var rightNavigationItems: [UIBarButtonItem] { get }
    var leftNavigationItems: [UIBarButtonItem] { get }
    var title: String? { get }
    var leftBarButtonItemTintColor: UIColor { get }
}

public extension NavigationContent {
    var rightNavigationItems: [UIBarButtonItem] { [] }

    var leftNavigationItems: [UIBarButtonItem] { [] }

    var title: String? { nil }

    var leftBarButtonItemTintColor: UIColor { .clear }
}

public class NoNavigationContent: NavigationContent {
    public var rightNavigationItems: [UIBarButtonItem] { [] }

    public var leftNavigationItems: [UIBarButtonItem] { [] }

    public var title: String? { nil }

    public var leftBarButtonItemTintColor: UIColor { .clear }

    public init() {}
}
