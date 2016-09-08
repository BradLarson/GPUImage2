import Foundation

// This reimplements CMTime such that it can reach across to Linux
public struct TimestampFlags: OptionSet {
    public let rawValue:UInt32
    public init(rawValue:UInt32) { self.rawValue = rawValue }
    
    public static let valid = TimestampFlags(rawValue: 1 << 0)
    public static let hasBeenRounded = TimestampFlags(rawValue: 1 << 1)
    public static let positiveInfinity = TimestampFlags(rawValue: 1 << 2)
    public static let negativeInfinity = TimestampFlags(rawValue: 1 << 3)
    public static let indefinite = TimestampFlags(rawValue: 1 << 4)
}

public struct Timestamp: Comparable {
    let value:Int64
    let timescale:Int32
    let flags:TimestampFlags
    let epoch:Int64
    
    public init(value:Int64, timescale:Int32, flags:TimestampFlags, epoch:Int64) {
        self.value = value
        self.timescale = timescale
        self.flags = flags
        self.epoch = epoch
    }
    
    func seconds() -> Double {
        return Double(value) / Double(timescale)
    }
}

public func ==(x:Timestamp, y:Timestamp) -> Bool {
    // TODO: Fix this
//    if (x.flags.contains(TimestampFlags.PositiveInfinity) && y.flags.contains(TimestampFlags.PositiveInfinity)) {
//        return true
//    } else if (x.flags.contains(TimestampFlags.NegativeInfinity) && y.flags.contains(TimestampFlags.NegativeInfinity)) {
//        return true
//    } else if (x.flags.contains(TimestampFlags.Indefinite) || y.flags.contains(TimestampFlags.Indefinite) || x.flags.contains(TimestampFlags.NegativeInfinity) || y.flags.contains(TimestampFlags.NegativeInfinity) || x.flags.contains(TimestampFlags.PositiveInfinity) && y.flags.contains(TimestampFlags.PositiveInfinity)) {
//        return false
//    }
    
    let correctedYValue:Int64
    if (x.timescale != y.timescale) {
        correctedYValue = Int64(round(Double(y.value) * Double(x.timescale) / Double(y.timescale)))
    } else {
        correctedYValue = y.value
    }
    
    return ((x.value == correctedYValue) && (x.epoch == y.epoch))
}

public func <(x:Timestamp, y:Timestamp) -> Bool {
    // TODO: Fix this
//    if (x.flags.contains(TimestampFlags.PositiveInfinity) || y.flags.contains(TimestampFlags.NegativeInfinity)) {
//        return false
//    } else if (x.flags.contains(TimestampFlags.NegativeInfinity) || y.flags.contains(TimestampFlags.PositiveInfinity)) {
//        return true
//    }

    if (x.epoch < y.epoch) {
        return true
    } else if (x.epoch > y.epoch) {
        return false
    }

    let correctedYValue:Int64
    if (x.timescale != y.timescale) {
        correctedYValue = Int64(round(Double(y.value) * Double(x.timescale) / Double(y.timescale)))
    } else {
        correctedYValue = y.value
    }

    return (x.value < correctedYValue)
}
