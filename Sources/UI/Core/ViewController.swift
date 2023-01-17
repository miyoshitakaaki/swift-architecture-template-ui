import UIKit
import Utility

open class ViewController: UIViewController, AnalyticsScreenView,
    UIAdaptivePresentationControllerDelegate
{
    open var screenNameForAnalytics: [AnalyticsScreen] { [] }

    open var screenEventForAnalytics: [AnalyticsEvent] { [] }

    override open func viewWillAppear(_ animated: Bool) {
        self.sendScreenView()
        super.viewWillAppear(animated)

        AnalyticsService.log(Self.className)
    }

    open func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.sendScreenView()

        AnalyticsService.log(Self.className)
    }
}
