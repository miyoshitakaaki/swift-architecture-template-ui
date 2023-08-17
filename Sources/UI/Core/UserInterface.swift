#if !os(macOS)
import UIKit

@MainActor
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
    ) {}
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
#endif
