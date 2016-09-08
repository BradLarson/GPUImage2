import Foundation

#if os(Linux)
// For now, disable GCD on Linux and run everything on the main thread

protocol SerialDispatch {
}
    
extension SerialDispatch {
    func runOperationAsynchronously(operation:() -> ()) {
        operation()
    }
    
    func runOperationSynchronously<T>(operation:() throws -> T) rethrows -> T {
        return try operation()
    }
}

#else

public let standardProcessingQueuePriority:DispatchQueue.GlobalQueuePriority = {
    // DispatchQueue.QoSClass.default
    if #available(iOS 10, OSX 10.10, *) {
        return DispatchQueue.GlobalQueuePriority.default
    } else {
        return DispatchQueue.GlobalQueuePriority.default
    }
}()
    
public let lowProcessingQueuePriority:DispatchQueue.GlobalQueuePriority = {
    if #available(iOS 10, OSX 10.10, *) {
        return DispatchQueue.GlobalQueuePriority.low
    } else {
        return DispatchQueue.GlobalQueuePriority.low
    }
}()

func runAsynchronouslyOnMainQueue(_ mainThreadOperation:@escaping () -> ()) {
    if (Thread.isMainThread) {
        mainThreadOperation()
    } else {
        DispatchQueue.main.async(execute:mainThreadOperation)
    }
}

func runOnMainQueue(_ mainThreadOperation:() -> ()) {
    if (Thread.isMainThread) {
        mainThreadOperation()
    } else {
        DispatchQueue.main.sync(execute:mainThreadOperation)
    }
}

func runOnMainQueue<T>(_ mainThreadOperation:() -> T) -> T {
    var returnedValue: T!
    runOnMainQueue {
        returnedValue = mainThreadOperation()
    }
    return returnedValue
}

// MARK: -
// MARK: SerialDispatch extension

public protocol SerialDispatch {
    var serialDispatchQueue:DispatchQueue { get }
    var dispatchQueueKey:DispatchSpecificKey<Int> { get }
    func makeCurrentContext()
}

public extension SerialDispatch {
    public func runOperationAsynchronously(_ operation:@escaping () -> ()) {
        self.serialDispatchQueue.async {
            self.makeCurrentContext()
            operation()
        }
    }
    
    public func runOperationSynchronously(_ operation:() -> ()) {
        // TODO: Verify this works as intended
        if (DispatchQueue.getSpecific(key:self.dispatchQueueKey) == 81) {
            operation()
        } else {
            self.serialDispatchQueue.sync {
                self.makeCurrentContext()
                operation()
            }
        }
    }
    
    public func runOperationSynchronously(_ operation:() throws -> ()) throws {
        var caughtError:Error? = nil
        runOperationSynchronously {
            do {
                try operation()
            } catch {
                caughtError = error
            }
        }
        if (caughtError != nil) {throw caughtError!}
    }
    
    public func runOperationSynchronously<T>(_ operation:() throws -> T) throws -> T {
        var returnedValue: T!
        try runOperationSynchronously {
            returnedValue = try operation()
        }
        return returnedValue
    }

    public func runOperationSynchronously<T>(_ operation:() -> T) -> T {
        var returnedValue: T!
        runOperationSynchronously {
            returnedValue = operation()
        }
        return returnedValue
    }
}
#endif
