public enum ImageOrientation {
    case Portrait
    case PortraitUpsideDown
    case LandscapeLeft
    case LandscapeRight
    
    func rotationNeededForOrientation(targetOrientation:ImageOrientation) -> Rotation {
        switch (self, targetOrientation) {
            case (.Portrait, .Portrait), (.PortraitUpsideDown, .PortraitUpsideDown), (.LandscapeLeft, .LandscapeLeft), (LandscapeRight, LandscapeRight): return .NoRotation
            case (.Portrait, .PortraitUpsideDown): return .Rotate180
            case (.PortraitUpsideDown, .Portrait): return .Rotate180
            case (.Portrait, .LandscapeLeft): return .RotateCounterclockwise
            case (.LandscapeLeft, .Portrait): return .RotateClockwise
            case (.Portrait, .LandscapeRight): return .RotateClockwise
            case (.LandscapeRight, .Portrait): return .RotateCounterclockwise
            case (.LandscapeLeft, .LandscapeRight): return .Rotate180
            case (.LandscapeRight, .LandscapeLeft): return .Rotate180
            case (.PortraitUpsideDown, .LandscapeLeft): return .RotateClockwise
            case (.LandscapeLeft, .PortraitUpsideDown): return .RotateCounterclockwise
            case (.PortraitUpsideDown, .LandscapeRight): return .RotateCounterclockwise
            case (.LandscapeRight, .PortraitUpsideDown): return .RotateClockwise
        }
    }
}

public enum Rotation {
    case NoRotation
    case RotateCounterclockwise
    case RotateClockwise
    case Rotate180
    case FlipHorizontally
    case FlipVertically
    case RotateClockwiseAndFlipVertically
    case RotateClockwiseAndFlipHorizontally
    
    func flipsDimensions() -> Bool {
        switch self {
            case .NoRotation, .Rotate180, .FlipHorizontally, .FlipVertically: return false
            case .RotateCounterclockwise, .RotateClockwise, .RotateClockwiseAndFlipVertically, .RotateClockwiseAndFlipHorizontally: return true
        }
    }
}
