#if !os(macOS)
import UIKit
import Utility

class VideoPlayerControlMenuView: UIView {
    enum State {
        case ready
        case isPlaying
        case pause
    }

    enum Display {
        case show
        case dismiss(after: TimeInterval = 3)
    }

    private let playButton: UIButton = .init(style: .init(style: { button in
        button.setImage(
            UIImage(
                systemName: "play.fill",
                withConfiguration: UIImage.SymbolConfiguration(
                    font: .systemFont(ofSize: 40)
                )
            ),
            for: .normal
        )
        button.frame.size = .init(width: 44, height: 44)
        button.tintColor = .white
    }))

    private let pauseButton: UIButton = .init(style: .init(style: { button in
        button.setImage(
            UIImage(
                systemName: "pause.fill",
                withConfiguration: UIImage.SymbolConfiguration(
                    font: .systemFont(ofSize: 40)
                )
            ),
            for: .normal
        )
        button.frame.size = .init(width: 44, height: 44)
        button.tintColor = .white
    }))

    private let seekBar: UISlider = {
        let seekBar = UISlider()
        seekBar.isContinuous = false
        return seekBar
    }()

    private let timeLabel: UILabel = .init(
        style: .init(style: { label in
            label.textColor = .white
        }),
        title: "00:00 / 00:00"
    )

    private let progressSubject: AVPlayerManager.ProgressSubject
    private let playHandler: () -> Void
    private let pauseHandler: () -> Void

    init(
        progressSubject: AVPlayerManager.ProgressSubject,
        playHandler: @escaping () -> Void,
        pauseHandler: @escaping () -> Void
    ) {
        self.progressSubject = progressSubject
        self.playHandler = playHandler
        self.pauseHandler = pauseHandler
        super.init(frame: .zero)
        self.setupView()
        self.setupEvent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var controlMenuDismissWorkItem: DispatchWorkItem?

    var state: State? {
        didSet {
            self.display = .show
        }
    }

    var display: Display? {
        didSet {
            guard let display else { return }

            switch display {
            case .show:
                showControlMenu()

            case let .dismiss(after):
                dismissControlMenu(after: after)
            }
        }
    }

    func adjustControlMenuPosition(offset: CGFloat) {
        self.seekBar.transform = .init(translationX: 0, y: offset)
        self.timeLabel.transform = .init(translationX: 0, y: offset - 32)
    }

    func seek(to: Float) {
        self.seekBar.value = to
    }

    func updateTimeLabelText(current: TimeInterval, duration: TimeInterval) {
        self.timeLabel.text = "\(current.timeFormatted()) / \(duration.timeFormatted())"
    }
}

private extension VideoPlayerControlMenuView {
    func setupView() {
        self.addSubviews(
            self.playButton,
            self.pauseButton,
            self.seekBar,
            self.timeLabel,

            constraints:
            self.playButton.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            self.playButton.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
            ),
            self.pauseButton.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            self.pauseButton.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
            ),
            self.seekBar.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            self.seekBar.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
            ),
            self.seekBar.widthAnchor.constraint(
                equalTo: self.safeAreaLayoutGuide.widthAnchor,
                constant: -16
            ),
            self.timeLabel.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            self.timeLabel.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
            ),
            self.timeLabel.widthAnchor.constraint(
                equalTo: self.safeAreaLayoutGuide.widthAnchor,
                constant: -16
            )
        )
    }

    func setupEvent() {
        self.playButton.addAction(.init(handler: { [weak self] _ in
            guard let self else { return }
            self.state = .isPlaying
            self.playHandler()
        }), for: .touchUpInside)

        self.pauseButton.addAction(.init(handler: { [weak self] _ in
            guard let self else { return }
            self.state = .pause
            self.pauseHandler()
        }), for: .touchUpInside)

        self.seekBar.addTarget(
            self,
            action: #selector(self.didStartDragSeekBar),
            for: .touchDown
        )
        self.seekBar.addTarget(
            self,
            action: #selector(self.didEndDragSeekBar),
            for: .valueChanged
        )
    }

    func showControlMenu() {
        guard let state else { return }

        switch state {
        case .ready:
            self.playButton.isHidden = false
            self.pauseButton.isHidden = true
            self.seekBar.isHidden = true
            self.timeLabel.isHidden = true
            self.backgroundColor = .lightGray.withAlphaComponent(0)

        case .isPlaying:
            self.playButton.isHidden = true
            self.pauseButton.isHidden = false
            self.seekBar.isHidden = false
            self.timeLabel.isHidden = false
            self.backgroundColor = .lightGray.withAlphaComponent(0.3)

            self.dismissControlMenu()

        case .pause:
            self.playButton.isHidden = false
            self.pauseButton.isHidden = true
            self.seekBar.isHidden = false
            self.timeLabel.isHidden = false
            self.backgroundColor = .lightGray.withAlphaComponent(0.3)

            self.dismissControlMenu()
        }
    }

    func dismissControlMenu(after: TimeInterval = 3) {
        self.controlMenuDismissWorkItem?.cancel()
        self.controlMenuDismissWorkItem = .init { [weak self] in
            guard let self else { return }

            UIView.transition(
                with: self,
                duration: 0.4,
                options: .transitionCrossDissolve,
                animations: {
                    self.playButton.isHidden = true
                    self.pauseButton.isHidden = true
                    self.seekBar.isHidden = true
                    self.timeLabel.isHidden = true
                    self.backgroundColor = .lightGray.withAlphaComponent(0)
                    self.display = .dismiss()
                }
            )
        }

        if let controlMenuDismissWorkItem {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + after,
                execute: controlMenuDismissWorkItem
            )
        }
    }

    @objc private func didStartDragSeekBar() {
        self.progressSubject.send((.startDragging, TimeInterval(self.seekBar.value)))
    }

    @objc private func didEndDragSeekBar() {
        self.progressSubject.send((.endDragging, TimeInterval(self.seekBar.value)))
    }
}
#endif
