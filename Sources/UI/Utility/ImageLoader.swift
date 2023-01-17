import UIKit

actor ImageLoader {
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
            case let .fetched(image):
                return image
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

        self.images[urlRequest] = .fetched(image)

        return image
    }

    private enum LoaderStatus {
        case inProgress(Task<UIImage, Error>)
        case fetched(UIImage)
    }
}
