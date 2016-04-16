public struct Color {
    public let red:Float
    public let green:Float
    public let blue:Float
    public let alpha:Float
    
    public init(red:Float, green:Float, blue:Float, alpha:Float = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public static let Black = Color(red:0.0, green:0.0, blue:0.0, alpha:1.0)
    public static let White = Color(red:1.0, green:1.0, blue:1.0, alpha:1.0)
    public static let Red = Color(red:1.0, green:0.0, blue:0.0, alpha:1.0)
    public static let Green = Color(red:0.0, green:1.0, blue:0.0, alpha:1.0)
    public static let Blue = Color(red:0.0, green:0.0, blue:1.0, alpha:1.0)
    public static let Transparent = Color(red:0.0, green:0.0, blue:0.0, alpha:0.0)
}