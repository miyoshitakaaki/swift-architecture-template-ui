import UIKit

public enum ReloadType {
    case local, remoteOnlySection, remote
}

public protocol Refreshable: UIViewController {
    // TODO: rename to setNeedReload
    func setNeedRefresh(reloadType: ReloadType)
}
