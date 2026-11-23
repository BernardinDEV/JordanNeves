#if DEBUG
import Foundation

/// Debug-only jump straight to a screen, driven by the `DEMO_ROUTE` environment
/// variable.
///
/// Exists so screenshots can be captured deterministically without tapping
/// through the whole flow:
///
///     SIMCTL_CHILD_DEMO_ROUTE=contract xcrun simctl launch booted <bundle-id-da-marca>
///
/// Compiled out of Release builds entirely.
enum DemoRoute: String {
    case onboarding
    case signIn
    case code
    case home
    case notifications
    case cases
    case caseDetail
    case sealedCase
    case movement
    case hearing
    case hearingConfirmed
    case documents
    case contract
    case upload
    case uploadSent
    case contact
    case profile

    /// Lido uma vez: o ambiente do processo não muda depois do lançamento.
    static let current: DemoRoute? = ProcessInfo.processInfo.environment["DEMO_ROUTE"]
        .flatMap(DemoRoute.init(rawValue:))
}
#endif
