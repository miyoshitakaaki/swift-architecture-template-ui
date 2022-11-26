import Combine
import Foundation
import UIKit

extension UIControl {
    final class Subscription<SubscriberType: Subscriber, Control: UIControl>: Combine.Subscription
        where SubscriberType.Input == Control
    {
        private var subscriber: SubscriberType?
        private let control: Control

        init(subscriber: SubscriberType, control: Control, event: UIControl.Event) {
            self.subscriber = subscriber
            self.control = control
            control.addTarget(self, action: #selector(self.eventHandler), for: event)
        }

        func request(_ demand: Subscribers.Demand) {
            // We do nothing here as we only want to send events when they occur.
            // See, for more info:
            // https://developer.apple.com/documentation/combine/subscribers/demand
        }

        func cancel() {
            self.subscriber = nil
        }

        @objc private func eventHandler() {
            _ = self.subscriber?.receive(self.control)
        }
    }

    public struct Publisher<Control: UIControl>: Combine.Publisher {
        public typealias Output = Control
        public typealias Failure = Never

        let control: Control
        let controlEvents: UIControl.Event

        public init(control: Control, events: UIControl.Event) {
            self.control = control
            self.controlEvents = events
        }

        public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure,
            Output == S.Input
        {
            let subscription = Subscription(
                subscriber: subscriber,
                control: control,
                event: controlEvents
            )
            subscriber.receive(subscription: subscription)
        }
    }
}

public protocol CombineCompatible {}
extension UIControl: CombineCompatible {}
public extension CombineCompatible where Self: UIControl {
    func publisher(for events: UIControl.Event) -> UIControl.Publisher<Self> {
        UIControl.Publisher(control: self, events: events)
    }
}

public extension CombineCompatible where Self: UISwitch {
    var isOnPublisher: AnyPublisher<Bool, Never> {
        self.publisher(for: [.allEditingEvents, .valueChanged]).map(\.isOn).eraseToAnyPublisher()
    }
}
