import Combine
import UIKit

public class PagingSectionFooterView: UICollectionReusableView {
    public struct PagingInfo: Equatable, Hashable {
        let sectionIndex: Int
        let currentPage: Int

        public init(sectionIndex: Int, currentPage: Int) {
            self.sectionIndex = sectionIndex
            self.currentPage = currentPage
        }
    }

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.isUserInteractionEnabled = true
        control.currentPageIndicatorTintColor = .systemOrange
        control.pageIndicatorTintColor = .systemGray5
        return control
    }()

    private var pagingInfoToken: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }

    public func configure(with numberOfPages: Int) {
        self.pageControl.numberOfPages = numberOfPages
    }

    public func subscribeTo(subject: PassthroughSubject<PagingInfo, Never>, for section: Int) {
        self.pagingInfoToken = subject
            .filter { $0.sectionIndex == section }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pagingInfo in
                self?.pageControl.currentPage = pagingInfo.currentPage
            }
    }

    private func setupView() {
        backgroundColor = .clear

        addSubview(self.pageControl)

        NSLayoutConstraint.activate([
            self.pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.pageControl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        self.pagingInfoToken?.cancel()
        self.pagingInfoToken = nil
    }
}
