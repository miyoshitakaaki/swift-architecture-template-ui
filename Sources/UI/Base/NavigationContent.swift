import UIKit

@MainActor
public protocol NavigationContent {
    var rightNavigationItems: [UIBarButtonItem] { get }
    var leftNavigationItems: [UIBarButtonItem] { get }
    var title: String? { get }
    var rightBarButtonItemTintColor: UIColor { get }
    var leftBarButtonItemTintColor: UIColor { get }
}

public extension NavigationContent {
    var rightNavigationItems: [UIBarButtonItem] { [] }

    var leftNavigationItems: [UIBarButtonItem] { [] }

    var title: String? { nil }

    var rightBarButtonItemTintColor: UIColor { .black }

    var leftBarButtonItemTintColor: UIColor { .clear }
}

public class TitleNavigationContent: NavigationContent {
    public var rightNavigationItems: [UIBarButtonItem] { [] }

    public var leftNavigationItems: [UIBarButtonItem] { [] }

    public var rightBarButtonItemTintColor: UIColor { .black }

    public var leftBarButtonItemTintColor: UIColor { .clear }

    public let title: String?

    public init(title: String? = "") {
        self.title = title
    }
}
