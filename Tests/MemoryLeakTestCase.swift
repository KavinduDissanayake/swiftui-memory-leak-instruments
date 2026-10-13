import XCTest
@testable import SwiftUIMemoryLeakInstruments

// MARK: - Reusable Memory Leak Unit Test Suite
open class BaseLeakTestCase: XCTestCase {
    
    /// Tracks an instance and asserts that it is deallocated after the test finishes.
    public func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "🚨 Memory Leak Detected: Potential retain cycle keeping instance alive in memory!",
                file: file,
                line: line
            )
        }
    }
}

// MARK: - Example Unit Test Asserting Deallocation
final class OrderViewModelLeakTests: BaseLeakTestCase {
    
    func test_safeViewModel_deallocatesCorrectly() {
        var sut: SafeOrderViewModel? = SafeOrderViewModel()
        
        // Register leak watcher
        trackForMemoryLeaks(sut!)
        
        sut?.startListening()
        
        // Simulate screen dismissal
        sut = nil
        
        // Passes! Instance deallocates cleanly.
    }
    
    func test_sleepCoordinatorFixed_doesNotDeadlock() {
        let coordinator = SleepSurveyCoordinator.shared
        // 1. Safe early return when top view controller is nil (lock is safely released via defer)
        coordinator.evaluateSleepSurveyTriggerFixed(startEpochms: 1000, endEpochms: 2000, topViewControllerIsNil: true)
        XCTAssertTrue(coordinator.shouldPresentSurvey)
        
        // 2. Full completion path
        coordinator.evaluateSleepSurveyTriggerFixed(startEpochms: 1000, endEpochms: 2000, topViewControllerIsNil: false)
        XCTAssertFalse(coordinator.shouldPresentSurvey)
    }
}
