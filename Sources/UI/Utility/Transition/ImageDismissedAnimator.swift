#if !os(macOS)
import UIKit

class ImageDismissedAnimator<
    Presenting: UIViewController,
    Presented: ImageDestinationTransitionType
>: NSObject, UIViewControllerAnimatedTransitioning {
    weak var targetView: UIImageView?

    private let duration: TimeInterval = 1

    init(targetView: UIImageView) {
        self.targetView = targetView
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
        -> TimeInterval
    {
        self.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let presented = transitionContext
            .viewController(forKey: UITransitionContextViewControllerKey.from)

        let presenting = transitionContext
            .viewController(forKey: UITransitionContextViewControllerKey.to)

        guard
            let presenting = presenting as? Presenting,
            let presented = presented as? Presented,
            let targetView
        else {
            transitionContext.cancelInteractiveTransition()
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(presenting.view)

        let animationView = UIView(frame: presented.view.frame)

        let backgroundView = UIView(frame: animationView.frame)
        backgroundView.backgroundColor = .white
        animationView.addSubview(backgroundView)

        let imageView = UIImageView(image: presented.imageView.image)
        imageView.contentMode = presented.imageView.contentMode
        imageView.frame = presented.imageView.frame
        animationView.addSubview(imageView)
        containerView.addSubview(animationView)

        let destinationFrame = targetView.superview!.convert(
            targetView.frame,
            to: containerView
        )

        let cellBackgroundView = UIView(frame: destinationFrame)
        cellBackgroundView.backgroundColor = .white
        containerView.insertSubview(cellBackgroundView, aboveSubview: presenting.view)

        let animation = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            backgroundView.alpha = 0
            imageView.frame = destinationFrame
        }

        animation.addCompletion { _ in
            cellBackgroundView.removeFromSuperview()
            animationView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
        animation.startAnimation()
    }
}
#endif
