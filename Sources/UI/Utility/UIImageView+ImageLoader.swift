import Nuke
import UIKit

public extension UIImageView {
    func loadImage(
        url: String?,
        defaultImage: UIImage,
        adjustHeight: Bool = false
    ) {
        if #available(iOS 15.2, *) {
            Task {
                self.image = try await ImageLoader.shared.fetch(
                    url: url,
                    defaultImage: defaultImage
                )

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
        } else {
            self.loadImageWithNuke(
                with: url,
                defaultImage: defaultImage,
                adjustHeight: adjustHeight
            )
        }
    }

    func loadImageWithNuke(
        with url: String?,
        defaultImage: UIImage?,
        adjustHeight: Bool = false
    ) {
        guard let url else {
            self.image = defaultImage
            return
        }

        guard let url = URL(string: url) else {
            self.contentMode = .scaleAspectFit
            self.image = defaultImage
            return
        }

        var request = ImageRequest(url: url)
        request.userInfo[.imageIdKey] = url.path
        Nuke.loadImage(with: request, into: self) { result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    self.image = defaultImage
                }
            default:
                break
            }

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
