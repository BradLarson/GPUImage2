// This reimplements CMTime such that it can reach across to Linux
public struct TimestampFlags: OptionSetType {
    public let rawValue:UInt32
    public init(rawValue:UInt32) { self.rawValue = rawValue }
    
    public static let Valid = TimestampFlags(rawValue: 1 << 0)
    public static let HasBeenRounded = TimestampFlags(rawValue: 1 << 1)
    public static let PositiveInfinity = TimestampFlags(rawValue: 1 << 2)
    public static let NegativeInfinity = TimestampFlags(rawValue: 1 << 3)
    public static let Indefinite = TimestampFlags(rawValue: 1 << 4)
}

public struct Timestamp {
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