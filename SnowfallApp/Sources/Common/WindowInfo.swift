import Cocoa
import CoreGraphics

class WindowInfo {
    private let statusBarSize = 38.0
    private let lauchpadLayer = 27

//    func getActiveWindowRect() -> CGRect? {
//        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
//        guard let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return nil }
//
//        guard !isLaunchpadVisible() else { return nil }
//
//        for windowInfo in windowListInfo {
//            guard let layer = windowInfo[kCGWindowLayer as String] as? Int,
//                  layer == 0,
//                  let windowBounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
//                  let x = windowBounds["X"] as? CGFloat,
//                  let y = windowBounds["Y"] as? CGFloat,
//                  let width = windowBounds["Width"] as? CGFloat else { continue }
//
//            if !(x == 0 && (y == statusBarSize || y == 0)) && width >= 50 {
//                return CGRect(x: x, y: y, width: width, height: 50.0)
//            } else {
//                return nil
//            }
//        }
//        return nil
//    }
    
    func frontmostAppPID() -> pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }
    
    func getActiveWindowRect() -> CGRect? {
        guard let activePID = frontmostAppPID(),
              !isLaunchpadVisible()
        else { return nil }

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]

        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
        else { return nil }

        for window in windowList {
            guard
                let pid = window[kCGWindowOwnerPID as String] as? pid_t,
                pid == activePID,
                let layer = window[kCGWindowLayer as String] as? Int,
                layer == 0,
                let bounds = window[kCGWindowBounds as String] as? [String: Any],
                let x = bounds["X"] as? CGFloat,
                let y = bounds["Y"] as? CGFloat,
                let width = bounds["Width"] as? CGFloat,
                let height = bounds["Height"] as? CGFloat
            else { continue }

            // отсекаем hover / tooltip окна
            guard width > 150, height > 150 else { continue }
            
            let alpha = window[kCGWindowAlpha as String] as? CGFloat ?? 1
            guard alpha > 0.9 else { continue }
            
            guard window[kCGWindowIsOnscreen as String] as? Bool == true else { continue }

            return CGRect(x: x, y: y, width: width, height: height)
        }

        return nil
    }

    func isLaunchpadVisible() -> Bool {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []

        for window in windowList {
            if let ownerName = window["kCGWindowOwnerName"] as? String, ownerName == "Dock",
               let layer = window["kCGWindowLayer"] as? Int {
                if layer == lauchpadLayer {
                    return true
                }
            }
        }
        return false
    }
    
    func cast(from global: CGRect, to local: CGRect, point: CGPoint) -> CGPoint {
        let x = point.x - local.origin.x
        let y = point.y - (global.height - (local.origin.y + local.height))
        return CGPoint(x: x, y: y)
    }
}
