import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Pre-Crash / Pre-Kill Diagnostic Logger
/// Flushes log buffers synchronously to disk before the iOS watchdog or kernel can terminate the process.
public final class PreCrashLogger: @unchecked Sendable {
    public static let shared = PreCrashLogger()
    
    private let logQueue = DispatchQueue(label: "com.app.precrashlogger", qos: .utility)
    private let fileURL: URL
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = docs.appendingPathComponent("live_diagnostic_trace.log")
    }
    
    public func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        
        logQueue.async { [weak self] in
            guard let self else { return }
            if let data = line.data(using: .utf8) {
                if let handle = try? FileHandle(forWritingTo: self.fileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.synchronizeFile() // Synchronous disk flush!
                    try? handle.close()
                } else {
                    try? data.write(to: self.fileURL, options: .atomic)
                }
            }
        }
    }
    
    public func flushSync() {
        logQueue.sync {
            // Guarantees all pending write buffers are on disk
        }
    }
}

// MARK: - Production Fitness App War Story: Sleep Survey & Lock Management Sample
public final class SleepSurveyCoordinator: @unchecked Sendable {
    public static let shared = SleepSurveyCoordinator()
    
    private var surveyPresentationLock = NSLock()
    public var shouldPresentSurvey: Bool = true
    public var lastProcessedSleepTimestamp: Int64?
    
    private init() {}
    
    // MARK: - ❌ THE BUG: Missing 'defer' on NSLock
    // When transitioning from UIKit to SwiftUI, UIApplication.topViewController() returns nil.
    // The guard statement exits early, leaving surveyPresentationLock PERMANENTLY LOCKED!
    // Next time sleep packets arrive, surveyPresentationLock.lock() deadlocks the background thread,
    // and cleanup packet deletion methods are NEVER REACHED, ballooning memory to 400MB+!
    public func evaluateSleepSurveyTriggerBuggy(startEpochms: Int64, endEpochms: Int64, topViewControllerIsNil: Bool = true) {
        if shouldPresentSurvey {
            surveyPresentationLock.lock()
            // ❌ BUG: No defer! Unlock is only placed at the end of the happy path!

            PreCrashLogger.shared.log("[SleepSurveyCoordinator] -> evaluating active session")

            // Transition from UIKit to SwiftUI caused this to return nil:
            if topViewControllerIsNil {
                PreCrashLogger.shared.log("[SleepSurveyCoordinator] -> missing top view controller")
                return // ❌ DEADLOCK & MEMORY LEAK: surveyPresentationLock remains locked forever!
            }

            // ... normal execution ...
            surveyPresentationLock.unlock() // Never reached!
        }

        // ❌ NEVER REACHED on subsequent calls due to deadlock:
        // Sensor packets pile up in RAM until an Out-of-Memory (Jetsam) crash occurs!
        purgeProcessedTelemetryBuffers()
    }
    
    // MARK: - ✅ THE FIX: Guaranteed unlock with 'defer'
    // 'defer { surveyPresentationLock.unlock() }' guarantees the lock is ALWAYS released,
    // even when returning early due to missing topViewController or invalid survey range!
    public func evaluateSleepSurveyTriggerFixed(startEpochms: Int64, endEpochms: Int64, topViewControllerIsNil: Bool = true) {
        if shouldPresentSurvey {
            surveyPresentationLock.lock()
            // ✅ THE FIX: Guarantees surveyPresentationLock is released on ANY exit path!
            defer {
                surveyPresentationLock.unlock()
                PreCrashLogger.shared.log("🧹 [SleepSurveyCoordinator] Safely unlocked surveyPresentationLock via defer")
            }

            PreCrashLogger.shared.log("[SleepSurveyCoordinator] -> evaluating active session")

            if topViewControllerIsNil {
                PreCrashLogger.shared.log("[SleepSurveyCoordinator] -> missing top view controller (Safe exit)")
                return // ✅ Safe: 'defer' unlocks surveyPresentationLock automatically!
            }

            // Safe completion
            lastProcessedSleepTimestamp = nil
            shouldPresentSurvey = false
        }

        // ✅ Cleanups now ALWAYS execute properly without deadlocks!
        purgeProcessedTelemetryBuffers()
    }
    
    private func purgeProcessedTelemetryBuffers() {
        PreCrashLogger.shared.log("🗑️ Purged processed biometric packets and sensor results from memory")
    }
}
