import Foundation
import Testing

// MARK: - Fakes

@MainActor
final class FakeApp: RunningAppHandle {
    let pid: pid_t
    var bundleID: String?
    var isRegular = true
    var isHidden = false
    /// Simulates macOS's unreliable hide() return value (it can hide yet return false).
    var hideReturnValue = true
    private(set) var hideCount = 0
    private(set) var unhideCount = 0

    init(pid: pid_t, bundleID: String? = nil) {
        self.pid = pid
        self.bundleID = bundleID
    }

    @discardableResult func hide() -> Bool {
        hideCount += 1
        isHidden = true
        return hideReturnValue
    }

    @discardableResult func unhide() -> Bool {
        unhideCount += 1
        isHidden = false
        return true
    }
}

@MainActor
final class FakeProvider: RunningAppProviding {
    var all: [FakeApp] = []
    var frontmostPid: pid_t?

    var apps: [any RunningAppHandle] { all }

    func app(pid: pid_t) -> (any RunningAppHandle)? {
        all.first { $0.pid == pid }
    }
}

// MARK: - Tests

@MainActor
struct FocusSessionTests {
    static let soloPid: pid_t = 999

    func makeSession(_ provider: FakeProvider) -> FocusSession {
        FocusSession(activationGuard: ActivationGuard(),
                     provider: provider,
                     soloPid: Self.soloPid)
    }

    @Test func hidesEligibleAppsAndKeepsFrontmost() {
        let provider = FakeProvider()
        let front = FakeApp(pid: 1)
        let other = FakeApp(pid: 2)
        let background = FakeApp(pid: 3)
        background.isRegular = false
        let solo = FakeApp(pid: Self.soloPid)
        provider.all = [front, other, background, solo]
        provider.frontmostPid = 1

        let session = makeSession(provider)
        session.activate()

        #expect(front.hideCount == 0)
        #expect(other.hideCount == 1)
        #expect(background.hideCount == 0)
        #expect(solo.hideCount == 0)
        #expect(session.sessionPids == [2])
        #expect(session.isActive)
        #expect(session.isManaging)
    }

    @Test func preHiddenAppsStayOutOfTheSession() {
        let provider = FakeProvider()
        let preHidden = FakeApp(pid: 2)
        preHidden.isHidden = true
        provider.all = [preHidden]
        provider.frontmostPid = 1

        let session = makeSession(provider)
        session.activate()
        #expect(session.sessionPids.isEmpty)

        session.deactivate()
        #expect(preHidden.unhideCount == 0) // never toggled back
    }

    /// Regression: on current macOS, hide() can hide the app yet return false.
    /// The session must record by intent, or restore silently loses apps.
    @Test func recordsIntentEvenWhenHideReturnsFalse() {
        let provider = FakeProvider()
        let liar = FakeApp(pid: 2)
        liar.hideReturnValue = false
        provider.all = [liar]
        provider.frontmostPid = 1

        let session = makeSession(provider)
        session.activate()
        #expect(session.sessionPids == [2])

        session.deactivate()
        #expect(liar.unhideCount == 1)
        #expect(!session.isActive)
    }

    /// Regression: isHidden can read stale after our own hide(); restore must
    /// call unhide() unconditionally rather than gating on isHidden.
    @Test func unhidesUnconditionallyOnDeactivate() {
        let provider = FakeProvider()
        let app = FakeApp(pid: 2)
        provider.all = [app]
        provider.frontmostPid = 1

        let session = makeSession(provider)
        session.activate()
        app.isHidden = false // simulate stale/manually-unhidden state

        session.deactivate()
        #expect(app.unhideCount == 1)
    }

    @Test func skipsAppsThatQuitMidSession() {
        let provider = FakeProvider()
        let survivor = FakeApp(pid: 2)
        let quitter = FakeApp(pid: 3)
        provider.all = [survivor, quitter]
        provider.frontmostPid = 1

        let session = makeSession(provider)
        session.activate()
        provider.all = [survivor] // pid 3 quit

        session.deactivate()
        #expect(survivor.unhideCount == 1)
        #expect(quitter.unhideCount == 0)
        #expect(!session.isActive)
    }

    @Test func doubleToggleReturnsToBaseline() {
        let provider = FakeProvider()
        let app = FakeApp(pid: 2)
        provider.all = [app]
        provider.frontmostPid = 1

        let session = makeSession(provider)
        session.toggle()
        #expect(session.isActive)
        session.toggle()
        #expect(!session.isActive)
        #expect(session.sessionPids.isEmpty)
        #expect(app.hideCount == 1)
        #expect(app.unhideCount == 1)

        // Repeatable without accumulating state.
        session.toggle()
        session.toggle()
        #expect(app.hideCount == 2)
        #expect(app.unhideCount == 2)
    }

    @Test func activateWhileActiveIsANoOp() {
        let provider = FakeProvider()
        let app = FakeApp(pid: 2)
        provider.all = [app]
        provider.frontmostPid = 1

        let session = makeSession(provider)
        session.activate()
        session.activate()
        #expect(app.hideCount == 1)
    }

    @Test func stateChangeCallbackFires() {
        let provider = FakeProvider()
        provider.all = [FakeApp(pid: 2)]
        provider.frontmostPid = 1

        let session = makeSession(provider)
        var changes = 0
        session.onStateChange = { changes += 1 }
        session.activate()
        session.deactivate()
        #expect(changes == 2)
    }
}
