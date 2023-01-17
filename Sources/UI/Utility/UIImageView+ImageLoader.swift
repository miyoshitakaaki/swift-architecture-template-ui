import UIKit

public extension UIImageView {
    func loadImage(
        url: String?,
        defaultImage: UIImage,
        adjustHeight: Bool = false
    ) {
        Task {
            self.image = try await ImageLoader.shared.fetch(url: url, defaultImage: defaultImage)

            if adjustHeight {
                if let imageSize = self.image?.size {
                    // 画像サイズに応じた高さに調整
                    self.translatesAutoresizingMaskIntoConstraints = false
                    self.heightAnchor.constraint(
                        equalTo: self.widthAnchor,
                        multiplier: imageSize.height / imageSize.width
                    ).isActive = true
                }
            }
        }
    }
}
