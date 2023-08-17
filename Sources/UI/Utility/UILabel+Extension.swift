#if !os(macOS)
import UIKit

public extension UILabel {
    func setSubTextColor(text: String, color: UIColor) {
        let attributedString = NSMutableAttributedString(string: self.text!)
        let range = attributedString.mutableString.range(
            of: text,
            options: NSString.CompareOptions.caseInsensitive
        )
        if range.location != NSNotFound {
            attributedString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: color,
                range: range
            )
        }
        self.attributedText = attributedString
    }
}
#endif
