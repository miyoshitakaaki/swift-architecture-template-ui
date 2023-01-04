import UIKit
import Utility

public protocol AnalyticsScreenName {
    var screenNameForAnalytics: [AnalyticsScreen] { get }
    var screenEventForAnalytics: [AnalyticsEvent] { get }
}

public extension AnalyticsScreenName {
    var screenNameForAnalytics: [AnalyticsScreen] { [] }
    var screenEventForAnalytics: [AnalyticsEvent] { [] }
}

public protocol AnalyticsScreenView: UIViewController, AnalyticsScreenName {}

public extension AnalyticsScreenView {
    func sendScreenView() {
        self.screenNameForAnalytics.forEach { item in
            Task.detached {
                await AnalyticsService.shared.sendScreen(screen: item)
            }
        }

        self.screenEventForAnalytics.forEach { item in
            Task.detached {
                await AnalyticsService.shared.sendEvent(item)
            }
        }
    }
}
