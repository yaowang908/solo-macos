import Foundation

/// Time-based suppression window for Smart Restore (design D4).
///
/// macOS gives no causality on app-activation events, so we cannot tell a
/// user-driven activation from one caused by Solo's own `hide()`/`unhide()`/raise.
/// Instead, Solo marks "a self-operation is in flight" around every such call and
/// Smart Restore ignores activations until a short quiet period has elapsed.
@MainActor
final class ActivationGuard {
    private let quietPeriod: TimeInterval
    private let now: () -> Date
    private var suppressUntil: Date = .distantPast

    /// `now` is injectable for tests; production uses the real clock.
    init(quietPeriod: TimeInterval = 0.5, now: @escaping () -> Date = Date.init) {
        self.quietPeriod = quietPeriod
        self.now = now
    }

    /// Call immediately before and after any Solo-initiated hide/unhide/raise.
    func noteSelfOperation() {
        let candidate = now().addingTimeInterval(quietPeriod)
        if candidate > suppressUntil {
            suppressUntil = candidate
        }
    }

    /// True while activations should be treated as self-caused and ignored.
    var isSuppressing: Bool {
        now() < suppressUntil
    }
}
