#if !os(macOS)
import UIKit

@MainActor
public protocol BottomFixedViewProtocol: UIView {
    func reload()
}
#endif
