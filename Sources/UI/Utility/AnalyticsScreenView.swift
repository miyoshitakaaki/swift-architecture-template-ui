import Utility

public protocol AnalyticsScreenView {
    static var screenNameForAnalytics: String { get }
}

public extension AnalyticsScreenView {
    static var screenNameForAnalytics: String { "" }

    static func sendScreenView() {
        AnalyticsService.shared.sendScreen(screenName: Self.screenNameForAnalytics)
    }
}
