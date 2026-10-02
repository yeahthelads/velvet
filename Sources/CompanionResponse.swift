import Foundation

/// Brief responses use eligible on-screen time, so hiding, pausing, and focus
/// never consume or unexpectedly replay a burst of movement.
struct CompanionResponse: Equatable {
    enum Phase { case idle, zoomies, reconciliation, shySmile }
    static let zoomiesDuration = 8.0
    static let reconciliationDuration = 90.0
    private(set) var latteWaiting = false
    private(set) var zoomiesRemaining = 0.0
    private(set) var reconciliationRemaining = 0.0
    private(set) var smileRemaining = 0.0
    private var nextSmile = 12.0
    var zoomiesElapsed: Double { Self.zoomiesDuration - zoomiesRemaining }
    var reconciliationElapsed: Double { Self.reconciliationDuration - reconciliationRemaining }
    var isActive: Bool { latteWaiting || phase != .idle }
    var isReconciling: Bool { reconciliationRemaining > 0 }
    var phase: Phase {
        if zoomiesRemaining > 0 { return .zoomies }
        if reconciliationRemaining > 0 { return smileRemaining > 0 ? .shySmile : .reconciliation }
        return .idle
    }
    mutating func acceptLatte(allowed: Bool) { cancelZoomies(); latteWaiting = allowed }
    mutating func startZoomies() { latteWaiting = false; zoomiesRemaining = Self.zoomiesDuration }
    mutating func cancelZoomies() { latteWaiting = false; zoomiesRemaining = 0 }
    mutating func comfort() {
        reconciliationRemaining = Self.reconciliationDuration
        smileRemaining = 0; nextSmile = 12
    }
    mutating func upset() { self = CompanionResponse() }
    mutating func advance(by seconds: Double, healthy: Bool, quiet: Bool, available: Bool) {
        if !healthy { cancelZoomies(); return }
        if quiet { cancelZoomies(); return }
        guard available, seconds.isFinite, seconds > 0 else { return }
        if latteWaiting { startZoomies() }
        if zoomiesRemaining > 0 {
            zoomiesRemaining = max(0, zoomiesRemaining - seconds)
            return
        }
        guard reconciliationRemaining > 0 else { return }
        reconciliationRemaining = max(0, reconciliationRemaining - seconds)
        if reconciliationRemaining == 0 { smileRemaining = 0; return }
        smileRemaining = max(0, smileRemaining - seconds)
        nextSmile -= seconds
        if nextSmile <= 0 { smileRemaining = 2.2; nextSmile = 16 }
    }
}
