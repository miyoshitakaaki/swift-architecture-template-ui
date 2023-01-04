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

        Task.detached {
            await AnalyticsService.shared.log(Self.className)
        }
    }

    open func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.sendScreenView()

        Task.detached {
            await AnalyticsService.shared.log(Self.className)
        }
    }
}
