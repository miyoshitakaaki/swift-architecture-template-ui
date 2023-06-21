import UIKit

public final class ImageTransitioningDelegate<
    Presenting: UIViewController,
    Presented: ImageDestinationTransitionType
>: NSObject, UIViewControllerTransitioningDelegate {
    weak var targetView: UIImageView?
    public var useImageDismissedAnimator = true

    public init(targetView: UIImageView) {
        self.targetView = targetView
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        ImagePresentedAnimator<Presenting, Presented>(
            targetView: self.targetView!
        )
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        self.useImageDismissedAnimator
            ? ImageDismissedAnimator<Presenting, Presented>(targetView: self.targetView!)
            : nil
    }
}
