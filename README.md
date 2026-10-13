# SwiftUI Memory Leak Detection & Xcode Instruments Playbook

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-blue.svg?style=flat)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)]()
[![Medium](https://img.shields.io/badge/Medium-Read%20Article-black?style=flat&logo=medium)](https://medium.com/@kcrdissanayake/the-instruments-playbook-that-finally-solved-my-swiftui-memory-leaks-11bd5a88c168)

Companion repository for the article:  
**["The Instruments Playbook That Finally Solved My SwiftUI Memory Leaks"](https://medium.com/@kcrdissanayake/the-instruments-playbook-that-finally-solved-my-swiftui-memory-leaks-11bd5a88c168)**  
*Diagnosing retain cycles, NSLock deadlocks, and missing cleanup deallocations to maintain 60fps SwiftUI rendering and optimal memory footprint in production.*

![The Instruments Playbook That Finally Solved My SwiftUI Memory Leaks](article/cover.png)

---

## 📖 Overview

This repository demonstrates real-world production memory leak diagnoses and thread synchronization bug fixes:

1. **The "Missing `defer`" Lock Deadlock (`SleepSurveyCoordinator`):**
   - Shows how an inherited team oversight—an unreleased `NSLock` caused by an unhandled `nil` in `UIApplication.topViewController()` during an earlier UIKit-to-SwiftUI transition—deadlocked background sync threads.
   - Shows how memory ballooned to 400MB+ because downstream telemetry buffers were never deallocated.
   - Demonstrates the one-line fix: `defer { surveyPresentationLock.unlock() }`.

2. **Reactive Retain Cycles (`LeakingOrderViewModel` vs `SafeOrderViewModel`):**
   - Demonstrates how strong closure capture `[self]` in Combine pipelines pins view models on the heap.
   - Demonstrates proper `[weak self]` capture and teardown deallocation.

3. **Automated CI Leak Assertions (`BaseLeakTestCase`):**
   - A reusable `XCTestCase` extension (`trackForMemoryLeaks(_:)`) leveraging `addTeardownBlock` to catch retain cycles on CI before pull requests are merged.

4. **Atomic Pre-Kill Diagnostic Logger (`PreCrashLogger`):**
   - Flushes logs synchronously to disk on critical state transitions before iOS Watchdog (`0x8badf00d`) or kernel Jetsam can terminate the process.

---

## 📂 Repository Structure

```text
swiftui-memory-leak-instruments/
├── Package.swift                    # Swift Package Manager definition
├── README.md                        # Project documentation
├── .gitignore                       # Git ignore file
├── Sources/
│   ├── FitnessSleepTrackingManager.swift  # PreCrashLogger & SleepSurveyCoordinator (Bug vs Fix)
│   └── LeakingViewModelExample.swift       # Retain cycle vs [weak self] patterns
├── Tests/
│   └── MemoryLeakTestCase.swift            # Automated XCTest memory leak assertions
└── article/
    ├── article.md                          # Full Medium draft publication
    └── cover.jpg                           # Article hero banner
```

---

## 🚀 Running Tests & Verification

You can run the test suite directly with Swift CLI:

```bash
swift test
```

Or open the package directly in Xcode:

```bash
open Package.swift
```

Press `Cmd + U` in Xcode to run the test suite.

---

## 🛠️ The Reusable CI Leak Watchdog

Add this helper to your unit test target to catch retain cycles automatically:

```swift
import XCTest

open class BaseLeakTestCase: XCTestCase {
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
```

---

## 🔗 Resources & Articles

* **Medium Article:** [The Instruments Playbook That Finally Solved My SwiftUI Memory Leaks](https://medium.com/@kcrdissanayake/the-instruments-playbook-that-finally-solved-my-swiftui-memory-leaks-11bd5a88c168)
* **Author:** Kavindu Dissanayake ([@KavinduDissanayake](https://github.com/KavinduDissanayake))
* **LinkedIn:** [Kavindu Dissanayake](https://www.linkedin.com/in/kcrdissanayake/)
