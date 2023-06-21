import AVFoundation
import Combine
import Foundation
import UIKit
import Utility

public final class VideoPlayerViewController<Presenting: UIViewController>: UIViewController,
    ImageDestinationTransitionType
{
    private let closeButton: UIButton = .init(style: .init(style: { button in
        button.setTitle("閉じる", for: .normal)
        button.setTitleColor(.white, for: .normal)
    }))

    public let imageView: UIImageView = .init(style: .init(style: { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
    }))

    private var playerManager: AVPlayerManager?

    private lazy var controlMenuView: VideoPlayerControlMenuView = .init(
        progressSubject: self.progressSubject
    ) { [weak self] in
        guard let self else { return }
        Task {
            await self.playerManager?.play(fromInitial: false)
        }
    } pauseHandler: { [weak self] in
        guard let self else { return }
        self.playerManager?.pause()
    }

    private let progressSubject: AVPlayerManager.ProgressSubject = .init()
    private var cancellable: Set<AnyCancellable> = []

    private let thumbnailImage: UIImage
    private let videoUrl: String?
    private let transisionDelegate: ImageTransitioningDelegate<
        Presenting,
        VideoPlayerViewController
    >

    private let initialDeviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

    public init(
        thumbnailImage: UIImage,
        videoUrl: String?,
        transisionDelegate: ImageTransitioningDelegate<Presenting, VideoPlayerViewController>
    ) {
        self.thumbnailImage = thumbnailImage
        self.transisionDelegate = transisionDelegate
        self.videoUrl = videoUrl
        super.init(nibName: nil, bundle: nil)

        self.transitioningDelegate = transisionDelegate
        self.imageView.image = thumbnailImage
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupPlayerManager()

        setupView()

        setupEvent()

        self.controlMenuView.isHidden = self.videoUrl == nil

        self.controlMenuView.state = .ready
    }

    override public func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        self.transisionDelegate.useImageDismissedAnimator = self
            .initialDeviceOrientation == UIDevice.current.orientation
        self.imageView.image = .init()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playerManager?.changeFrame(bounds: self.imageView.bounds)
        self.adjustSeekBarPosition()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        self.playerManager?.pause()
        self.imageView.image = self.thumbnailImage
        super.viewWillDisappear(animated)
    }

    @objc func toggleControlMenuDisplay() {
        switch self.controlMenuView.display ?? .show {
        case .show:
            self.controlMenuView.display = .dismiss(after: 0)

        case .dismiss:
            self.controlMenuView.display = .show
        }
    }

    @objc func handleViewPanned(sender: UIPanGestureRecognizer) {
        self.controlMenuView.display = .dismiss(after: 0)

        let translation = sender.translation(in: view)
        let progress = abs(translation.y) / view.frame.height

        switch sender.state {
        case .changed:
            UIView.animate(
                withDuration: 0.0,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 1,
                options: .curveEaseOut,
                animations: {
                    self.imageView.transform = CGAffineTransform(
                        translationX: translation.x,
                        y: translation.y
                    )
                }
            )
        case .cancelled:
            break

        case .ended:
            let velocity = sender.velocity(in: view).y

            if progress + abs(velocity) / view.bounds.height > 0.8 {
                self.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(
                    withDuration: 0.0,
                    delay: 0,
                    usingSpringWithDamping: 0.7,
                    initialSpringVelocity: 1,
                    options: .curveEaseOut,
                    animations: {
                        self.imageView.transform = .identity
                    }
                )
            }
        default:
            break
        }
    }
}

private extension VideoPlayerViewController {
    func adjustSeekBarPosition() {
        let isPortrait = self.view.safeAreaLayoutGuide.layoutFrame.height > self.view
            .safeAreaLayoutGuide.layoutFrame.width
        if isPortrait {
            let imageViewWidth = self.view.safeAreaLayoutGuide.layoutFrame.width
            let imageWidth = self.thumbnailImage.size.width
            let imageHeight = self.thumbnailImage.size.height
            let imageHeightCalculated = imageHeight / imageWidth * imageViewWidth
            self.controlMenuView.adjustControlMenuPosition(offset: imageHeightCalculated / 2 - 16)
        } else {
            self.controlMenuView
                .adjustControlMenuPosition(
                    offset: self.view.safeAreaLayoutGuide.layoutFrame
                        .height / 2 - 16
                )
        }
    }

    func setupPlayerManager() {
        if let videoUrl {
            self.playerManager = AVPlayerManager(
                url: videoUrl,
                view: self.imageView,
                progressSubject: self.progressSubject
            )
        }
    }

    func setupView() {
        view.edgeToSelf(self.imageView)

        view.addSubviews(
            self.closeButton,

            constraints:
            self.closeButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            self.closeButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            )
        )

        self.imageView.edgeToSelf(self.controlMenuView)
    }

    func setupEvent() {
        self.closeButton.addAction(.init(handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }), for: .touchUpInside)

        view.addGestureRecognizer(UIPanGestureRecognizer(
            target: self,
            action: #selector(self.handleViewPanned)
        ))

        self.imageView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(self.toggleControlMenuDisplay)
        ))

        self.progressSubject.sink { [weak self] status, seekRate in
            guard let self, let duration = playerManager?.duration, !seekRate.isNaN else { return }

            print(seekRate)

            switch status {
            case .playing:
                self.controlMenuView.seek(to: Float(seekRate))

            case .startDragging:
                self.controlMenuView.state = .pause
                self.playerManager?.startDragging()

            case .endDragging:
                self.controlMenuView.state = .isPlaying
                self.playerManager?.endDragging(seekBarValue: seekRate)
            }

            self.controlMenuView.updateTimeLabelText(
                current: seekRate * duration,
                duration: duration
            )

        }.store(in: &self.cancellable)
    }
}
