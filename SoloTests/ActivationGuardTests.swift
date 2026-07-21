import Foundation
import Testing

@MainActor
struct ActivationGuardTests {
    @Test func startsUnsuppressed() {
        let guard_ = ActivationGuard(quietPeriod: 0.5, now: { Date(timeIntervalSinceReferenceDate: 0) })
        #expect(!guard_.isSuppressing)
    }

    @Test func suppressesForQuietPeriodAfterSelfOperation() {
        var now = Date(timeIntervalSinceReferenceDate: 0)
        let guard_ = ActivationGuard(quietPeriod: 0.5, now: { now })

        guard_.noteSelfOperation()
        #expect(guard_.isSuppressing)

        now = Date(timeIntervalSinceReferenceDate: 0.49)
        #expect(guard_.isSuppressing)

        now = Date(timeIntervalSinceReferenceDate: 0.51)
        #expect(!guard_.isSuppressing)
    }

    @Test func repeatedOperationsExtendTheWindow() {
        var now = Date(timeIntervalSinceReferenceDate: 0)
        let guard_ = ActivationGuard(quietPeriod: 0.5, now: { now })

        guard_.noteSelfOperation()
        now = Date(timeIntervalSinceReferenceDate: 0.4)
        guard_.noteSelfOperation() // extends to 0.9

        now = Date(timeIntervalSinceReferenceDate: 0.6)
        #expect(guard_.isSuppressing)

        now = Date(timeIntervalSinceReferenceDate: 0.91)
        #expect(!guard_.isSuppressing)
    }

    @Test func earlierDeadlineNeverShortensTheWindow() {
        var now = Date(timeIntervalSinceReferenceDate: 0)
        let longGuard = ActivationGuard(quietPeriod: 0.5, now: { now })

        longGuard.noteSelfOperation() // until 0.5
        // A hypothetical second note "in the past" must not pull the deadline in.
        now = Date(timeIntervalSinceReferenceDate: -1)
        longGuard.noteSelfOperation() // candidate -0.5 < 0.5 → unchanged

        now = Date(timeIntervalSinceReferenceDate: 0.49)
        #expect(longGuard.isSuppressing)
    }
}
