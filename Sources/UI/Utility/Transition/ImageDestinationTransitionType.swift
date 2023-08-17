#if !os(macOS)
import UIKit

public protocol ImageDestinationTransitionType: UIViewController {
    var imageView: UIImageView { get }
}
#endif
