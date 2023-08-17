#if !os(macOS)
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
        self.screenNameForAnalytics.forEach(AnalyticsService.sendScreen)
        self.screenEventForAnalytics.forEach(AnalyticsService.sendEvent)
    }
}
#endif
