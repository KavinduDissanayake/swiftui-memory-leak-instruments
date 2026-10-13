import Foundation
import Combine

// MARK: - Leaking Pattern (Before) vs Safe Pattern (After)

// MARK: ❌ 1. THE LEAKING PATTERN
public final class LeakingOrderViewModel: ObservableObject {
    @Published public var orderStatus: String = "Pending"
    private var cancellables = Set<AnyCancellable>()
    
    // Leaks because 'self' is strongly retained by the closure,
    // and self owns 'cancellables' which owns the subscription!
    public func startListening() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [self] _ in // Strong capture of self!
                self.orderStatus = "Updated at \(Date())"
            }
            .store(in: &cancellables)
    }
}

// MARK: ✅ 2. THE FIXED NON-LEAKING PATTERN
public final class SafeOrderViewModel: ObservableObject {
    @Published public var orderStatus: String = "Pending"
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        print("✅ SafeOrderViewModel successfully deallocated from memory!")
    }
    
    // Correctly captures [weak self] to allow ARC reference count to drop to zero
    public func startListening() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.orderStatus = "Updated at \(Date())"
            }
            .store(in: &cancellables)
    }
}
