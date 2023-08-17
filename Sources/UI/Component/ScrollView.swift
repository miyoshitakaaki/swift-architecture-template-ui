#if !os(macOS)
import UIKit

public final class ScrollView: UIScrollView {
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }
}
#endif
