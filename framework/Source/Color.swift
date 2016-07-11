public struct Color {
    public let redComponent:Float
    public let greenComponent:Float
    public let blueComponent:Float
    public let alphaComponent:Float
    
    public init(red:Float, green:Float, blue:Float, alpha:Float = 1.0) {
        self.redComponent = red
        self.greenComponent = green
        self.blueComponent = blue
        self.alphaComponent = alpha
    }
    
    public static let black = Color(red:0.0, green:0.0, blue:0.0, alpha:1.0)
    public static let white = Color(red:1.0, green:1.0, blue:1.0, alpha:1.0)
    public static let red = Color(red:1.0, green:0.0, blue:0.0, alpha:1.0)
    public static let green = Color(red:0.0, green:1.0, blue:0.0, alpha:1.0)
    public static let blue = Color(red:0.0, green:0.0, blue:1.0, alpha:1.0)
    public static let transparent = Color(red:0.0, green:0.0, blue:0.0, alpha:0.0)
}
