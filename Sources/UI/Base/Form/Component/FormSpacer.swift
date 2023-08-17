#if !os(macOS)
import UIKit

public final class FormSpacer: UIView {
    private let spacer: UIView = .init(frame: .zero)

    public init(_ height: CGFloat, backgroundColor: UIColor = .clear, margin: CGFloat = .zero) {
        super.init(frame: .zero)
        self.addSubviews(
            self.spacer,
            constraints:
            self.spacer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            self.spacer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            self.spacer.topAnchor.constraint(equalTo: topAnchor),
            self.spacer.bottomAnchor.constraint(equalTo: bottomAnchor)
        )
        self.spacer.backgroundColor = backgroundColor
        self.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
#endif
