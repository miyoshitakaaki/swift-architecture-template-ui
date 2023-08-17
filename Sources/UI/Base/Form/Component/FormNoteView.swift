#if !os(macOS)
import UIKit

public final class FormNoteView: UIView {
    private let detailMessageLabel: PaddingLabel

    public init(frame: CGRect = .zero, note: String) {
        self.detailMessageLabel = {
            let label = PaddingLabel(
                frame: .zero,
                text: "",
                cornerRadius: 8,
                style: .init {
                    $0.backgroundColor = .white
                    $0.font = UIFont.systemFont(ofSize: 12)
                    $0.layer.borderColor = UIColor.rgba(224, 224, 224, 1).cgColor
                    $0.layer.borderWidth = 1.0
                    $0.layer.cornerRadius = 8.0
                    $0.clipsToBounds = true
                }
            )
            var attributes: [NSAttributedString.Key: Any] = [:]
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5.0
            paragraphStyle.alignment = .left
            attributes.updateValue(paragraphStyle, forKey: .paragraphStyle)
            label.attributedText = NSAttributedString(
                string: note,
                attributes: attributes
            )
            label.numberOfLines = 4
            return label
        }()

        super.init(frame: frame)

        self.edgeToSelf(self.detailMessageLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
