import Foundation
@testable import SwissEphemeris

/// Information about an aspect between two planets
public struct AspectInfo {
    public let planetA: Planet
    public let planetB: Planet
    public let aspect: Aspect
    public let orb: Double
    
    public init(planetA: Planet, planetB: Planet, aspect: Aspect, orb: Double) {
        self.planetA = planetA
        self.planetB = planetB
        self.aspect = aspect
        // Ensure orb is always positive
        self.orb = abs(orb)
    }
    
    /// True if the aspect is applying (planets moving closer together)
    public var isApplying: Bool {
        // This would require speed calculations to determine properly
        // For now, we'll return false as a placeholder
        false
    }
}
