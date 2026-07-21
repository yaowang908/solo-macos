import ApplicationServices
import Foundation
import Testing

@MainActor
struct WindowInspectorTests {
    // MARK: - Eligibility (isRestorable)

    /// Regression: Outlook's and Notes' minimized main windows report AXDialog
    /// on current macOS; the blocklist must accept them.
    @Test func acceptsMinimizedDialogSubrole() {
        #expect(WindowInspector.isRestorable(
            role: kAXWindowRole as String, subrole: "AXDialog",
            minimized: true, area: 900_000))
    }

    @Test func acceptsStandardAndUnknownSubroles() {
        #expect(WindowInspector.isRestorable(
            role: kAXWindowRole as String, subrole: kAXStandardWindowSubrole as String,
            minimized: true, area: 900_000))
        #expect(WindowInspector.isRestorable(
            role: kAXWindowRole as String, subrole: nil,
            minimized: true, area: 900_000))
    }

    @Test func rejectsBlocklistedSubroles() {
        for subrole in WindowInspector.excludedSubroles {
            #expect(!WindowInspector.isRestorable(
                role: kAXWindowRole as String, subrole: subrole,
                minimized: true, area: 900_000))
        }
    }

    @Test func rejectsNonWindowsUnminimizedAndTinyWindows() {
        #expect(!WindowInspector.isRestorable(
            role: "AXSheet", subrole: nil, minimized: true, area: 900_000))
        #expect(!WindowInspector.isRestorable(
            role: nil, subrole: nil, minimized: true, area: 900_000))
        #expect(!WindowInspector.isRestorable(
            role: kAXWindowRole as String, subrole: nil, minimized: false, area: 900_000))
        // Below the 100x50 size floor.
        #expect(!WindowInspector.isRestorable(
            role: kAXWindowRole as String, subrole: nil, minimized: true, area: 4_999))
    }

    // MARK: - Selection priority (selectIndex)

    @Test func prefersMainWindow() {
        let candidates = [
            WindowInspector.MinimizedCandidate(isMain: false, area: 1_000_000),
            WindowInspector.MinimizedCandidate(isMain: true, area: 10_000),
        ]
        #expect(WindowInspector.selectIndex(candidates) == 1)
    }

    @Test func fallsBackToLargest() {
        let candidates = [
            WindowInspector.MinimizedCandidate(isMain: false, area: 10_000),
            WindowInspector.MinimizedCandidate(isMain: false, area: 500_000),
            WindowInspector.MinimizedCandidate(isMain: false, area: 20_000),
        ]
        #expect(WindowInspector.selectIndex(candidates) == 1)
    }

    @Test func singleCandidateWins() {
        let one = [WindowInspector.MinimizedCandidate(isMain: false, area: 42)]
        #expect(WindowInspector.selectIndex(one) == 0)
    }

    @Test func emptyReturnsNil() {
        #expect(WindowInspector.selectIndex([]) == nil)
    }
}
