#if !os(macOS)
import UIKit

@available(iOS 14.0, *)
open class NoSelectionStyleCell: UICollectionViewListCell {
    override public func updateConfiguration(using state: UICellConfigurationState) {
        if state.isSelected || state.isHighlighted {
            var back = UIBackgroundConfiguration.listPlainCell().updated(for: state)
            let v = UIView()
            if state.isSelected || state.isHighlighted {
                let v2 = UIView()
                v2.backgroundColor = .white
                v.addSubview(v2)
                v2.frame = v.bounds
                v2.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            back.customView = v

            self.backgroundConfiguration = back
        }
        super.updateConfiguration(using: state)
    }
}
#endif
