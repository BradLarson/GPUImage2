import Foundation

public var standardProcessingQueue:DispatchQueue {
if #available(iOS 10, OSX 10.10, *) {
        return DispatchQueue.global(qos: .default)
} else {
        return DispatchQueue.global(priority: .default)
    }
}

public var lowProcessingQueue:DispatchQueue {
if #available(iOS 10, OSX 10.10, *) {
        return DispatchQueue.global(qos: .background)
} else {
        return DispatchQueue.global(priority: .low)
    }
}

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
    func runOperationAsynchronously(_ operation:@escaping () -> ()) {
        self.serialDispatchQueue.async {
            self.makeCurrentContext()
            operation()
        }
    }
    
    func runOperationSynchronously(_ operation:() -> ()) {
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
    
    func runOperationSynchronously(_ operation:() throws -> ()) throws {
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
    
    func runOperationSynchronously<T>(_ operation:() throws -> T) throws -> T {
        var returnedValue: T!
        try runOperationSynchronously {
            returnedValue = try operation()
        }
        return returnedValue
    }

    func runOperationSynchronously<T>(_ operation:() -> T) -> T {
        var returnedValue: T!
        runOperationSynchronously {
            returnedValue = operation()
        }
        return returnedValue
    }
}
