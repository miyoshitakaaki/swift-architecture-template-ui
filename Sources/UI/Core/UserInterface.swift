import UIKit

public protocol UserInterface {
    func setupNavigationBar(
        navigationBar: UINavigationBar?,
        navigationItem: UINavigationItem?
    )
    func setupView(rootview: UIView)
}

public extension UserInterface {
    func setupNavigationBar(
        navigationBar: UINavigationBar? = nil,
        navigationItem: UINavigationItem? = nil
    ) {
        self.setupNavigationBar(
            navigationBar: navigationBar,
            navigationItem: navigationItem
        )
    }
}

public class NoUserInterface: UserInterface {
    public init() {}

    public func setupNavigationBar(
        navigationBar: UINavigationBar,
        navigationItem: UINavigationItem
    ) {
        assertionFailure("no need to implement")
    }

    public func setupView(rootview: UIView) {
        assertionFailure("no need to implement")
    }
}
