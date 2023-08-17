#if !os(macOS)
import UIKit

public enum ReloadType {
    case local, remoteOnlySection(sections: [Int] = []), remote(force: Bool = false)
}
#endif
