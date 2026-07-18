import Foundation

/// Append-to-file logger for prototype diagnostics. Compiled to a no-op outside
/// DEBUG builds, so it can stay wired in permanently while the prototype is
/// being validated. Read the output at /tmp/solo-debug.log.
enum DebugLog {
    #if DEBUG
    private static let url = URL(fileURLWithPath: "/tmp/solo-debug.log")
    private static let queue = DispatchQueue(label: "solo.debuglog")
    #endif

    static func write(_ message: @autoclosure () -> String) {
        #if DEBUG
        let line = "\(Date()) \(message())\n"
        queue.async {
            guard let data = line.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            } else {
                try? data.write(to: url)
            }
        }
        #endif
    }
}
