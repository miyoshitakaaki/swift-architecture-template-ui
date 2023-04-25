import UIKit

@globalActor
actor ImageLoader {
    private enum LoaderStatus {
        case inProgress(Task<UIImage, Error>)
        case fetched(String)
    }

    static let shared: ImageLoader = .init()

    private var images: [URLRequest: LoaderStatus] = [:]

    private init() {}

    func fetch(
        url: String?,
        defaultImage: UIImage
    ) async throws -> UIImage {
        guard let url else {
            return defaultImage
        }

        guard let url = URL(string: url) else {
            return defaultImage
        }

        let urlRequest = URLRequest(url: url)

        if let status = images[urlRequest] {
            switch status {
            case let .fetched(fileName):
                return self.getImage(fileName: fileName) ?? defaultImage
            case let .inProgress(task):
                return try await task.value
            }
        }

        let task: Task<UIImage, Error> = Task {
            let (imageData, _) = try await URLSession.shared.data(for: urlRequest)
            let image = UIImage(data: imageData) ?? defaultImage
            return image
        }

        self.images[urlRequest] = .inProgress(task)

        let image = try await task.value

        let fileName = url.lastPathComponent

        if self.fileExist(fileName: fileName) == false {
            self.saveFile(image: image, fileName: fileName)
        }

        self.images[urlRequest] = .fetched(fileName)

        return image
    }

    private func getFileURL(fileName: String) -> URL? {
        guard
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first else { return nil }
        return docDir.appendingPathComponent(fileName)
    }

    private func getImage(fileName: String) -> UIImage? {
        guard let path = getFileURL(fileName: fileName)?.path else { return nil }
        return UIImage(contentsOfFile: path)
    }

    private func saveFile(image: UIImage, fileName: String) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }

        guard let url = getFileURL(fileName: fileName) else { return }

        do {
            try imageData.write(to: url)
            print("Image saved.")
        } catch {
            print("Failed to save the image:", error)
        }
    }

    private func fileExist(fileName: String) -> Bool {
        guard let path = getFileURL(fileName: fileName)?.path else { return false }
        return FileManager.default.fileExists(atPath: path)
    }
}
