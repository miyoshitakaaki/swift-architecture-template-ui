import Combine
import UIKit

public class ImageSaver: NSObject {
    public let successPublisher = PassthroughSubject<Bool, Never>()

    public func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.didFinishSavingImage), nil)
    }

    @objc func didFinishSavingImage(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        if error != nil {
            self.successPublisher.send(false)
        } else {
            self.successPublisher.send(true)
        }
    }
}
