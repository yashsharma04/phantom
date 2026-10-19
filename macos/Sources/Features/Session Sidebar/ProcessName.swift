import Darwin
import Foundation

enum ProcessName {
    // proc_info.h defines this as (4 * MAXPATHLEN). Swift does not import that macro.
    private static let PROC_PIDPATHINFO_MAXSIZE = 4 * MAXPATHLEN

    static func basename(pid: Int32) -> String? {
        guard pid > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        let path = String(cString: buffer)
        let name = (path as NSString).lastPathComponent
        return name.isEmpty ? nil : name
    }
}
