//
//  TransitChart.swift
//  
//
//  Created by Swiss Ephemeris Extension
//

import Foundation

/// A transit chart comparing current planetary positions to natal positions
public struct TransitChart {
    
    /// The natal chart being transited
    public let natalChart: NatalChart
    
    /// The current date for transit calculations
    public let transitDate: Date
    
    /// Current planetary positions
    public let transitPlanets: PlanetaryPositions
    
    /// Current lunar node positions
    public let transitLunarNodes: LunarNodePositions
    
    /// Current asteroid positions
    public let transitAsteroids: AsteroidPositions
    
    /// Current house cusps for the transit time
    public let transitHouses: HouseCusps
    
    /// Aspects between transiting planets and natal planets
    public let transitAspects: [TransitAspectInfo]
    
    /// Creates a transit chart
    /// - Parameters:
    ///   - natalChart: The natal chart to compare against
    ///   - transitDate: The date for transit calculations
    ///   - aspectOrb: Orb in degrees for aspect calculations (default: 8.0)
    public init(natalChart: NatalChart,
                transitDate: Date,
                aspectOrb: Double = 8.0) {
        self.natalChart = natalChart
        self.transitDate = transitDate
        
        // Calculate current planetary positions
        self.transitPlanets = PlanetaryPositions(date: transitDate)
        self.transitLunarNodes = LunarNodePositions(date: transitDate)

        // Calculate transit asteroids using the same list from the natal chart.
        let asteroidsForTransit = natalChart.asteroids.all.map { $0.body }
        self.transitAsteroids = AsteroidPositions(date: transitDate, asteroids: asteroidsForTransit)
        
        // Calculate transit houses using the same location and house system as natal chart
        self.transitHouses = HouseCusps(date: transitDate, 
                                      latitude: natalChart.latitude, 
                                      longitude: natalChart.longitude, 
                                      houseSystem: natalChart.houseSystem)
        
        // Calculate transit aspects
        var calculatedTransitAspects: [TransitAspectInfo] = []
        
        // Transit planets to natal planets
        for transitPlanet in Planet.allCases {
            for natalPlanet in Planet.allCases {
                let transitCoord = Coordinate(body: transitPlanet, date: transitDate)
                let natalCoord = Coordinate(body: natalPlanet, date: natalChart.date)
                
                if let aspect = Aspect(a: transitCoord.longitude, b: natalCoord.longitude, orb: aspectOrb) {
                    calculatedTransitAspects.append(TransitAspectInfo(
                        transitPlanet: transitPlanet,
                        natalPlanet: natalPlanet,
                        aspect: aspect,
                        orb: aspect.remainder,
                        transitCoordinate: transitCoord,
                        natalCoordinate: natalCoord
                    ))
                }
            }
        }
        
        self.transitAspects = calculatedTransitAspects
    }
    
    /// Get specific transits for a natal planet
    /// - Parameter natalPlanet: The natal planet to find transits for
    /// - Returns: Array of transit aspects to that natal planet
    public func transitsTo(_ natalPlanet: Planet) -> [TransitAspectInfo] {
        return transitAspects.filter { $0.natalPlanet == natalPlanet }
    }
    
    /// Get transits from a specific transiting planet
    /// - Parameter transitPlanet: The transiting planet
    /// - Returns: Array of aspects from that transiting planet
    public func transitsFrom(_ transitPlanet: Planet) -> [TransitAspectInfo] {
        return transitAspects.filter { $0.transitPlanet == transitPlanet }
    }
    
    /// Determines the house of a transiting planet
    /// - Parameter planet: The transiting planet for which to find the house
    /// - Returns: The house number (1-12) the planet is in, or nil if not found
    public func house(for planet: Planet) -> Int? {
        return transitPlanets.house(of: planet, in: transitHouses, system: natalChart.houseSystem)
    }
    
    /// Determines the house of a transiting asteroid
    /// - Parameter asteroid: The transiting asteroid for which to find the house
    /// - Returns: The house number (1-12) the asteroid is in, or nil if not found
    public func house(for asteroid: Asteroid) -> Int? {
        return transitAsteroids.house(of: asteroid, in: transitHouses, system: natalChart.houseSystem)
    }
    
    /// Determines the house of a transiting lunar node
    /// - Parameter nodeType: The type of lunar node (true or mean)
    /// - Returns: The house number (1-12) the node is in, or nil if not found
    public func house(for nodeType: LunarNodeType) -> Int? {
        let nodeCoordinate: Coordinate<LunarNorthNode>
        switch nodeType {
        case .trueNode:
            nodeCoordinate = transitLunarNodes.trueNode
        case .meanNode:
            nodeCoordinate = transitLunarNodes.meanNode
        }
        
        switch natalChart.houseSystem {
        case .wholeSign:
            let ascLongitude = transitHouses.ascendent.tropical.value
            let ascSignIndex = Int(floor(ascLongitude / 30.0)) % 12
            let nodeSignIndex = Int(floor(nodeCoordinate.tropical.value / 30.0)) % 12
            let idx = (nodeSignIndex - ascSignIndex + 12) % 12
            return idx + 1
        default:
            return transitHouses.house(for: nodeCoordinate.longitude)
        }
    }
}

/// Enum to specify which type of lunar node
public enum LunarNodeType {
    case trueNode
    case meanNode
}

/// Information about a transit aspect between a transiting planet and natal planet
public struct TransitAspectInfo {
    public let transitPlanet: Planet
    public let natalPlanet: Planet
    public let aspect: Aspect
    public let orb: Double
    public let transitCoordinate: Coordinate<Planet>
    public let natalCoordinate: Coordinate<Planet>

    public init(transitPlanet: Planet, natalPlanet: Planet, aspect: Aspect, orb: Double, transitCoordinate: Coordinate<Planet>, natalCoordinate: Coordinate<Planet>) {
        self.transitPlanet = transitPlanet
        self.natalPlanet = natalPlanet
        self.aspect = aspect
        self.orb = abs(orb)
        self.transitCoordinate = transitCoordinate
        self.natalCoordinate = natalCoordinate
    }
    
    /// The exact degree difference
    public var exactDegree: Double {
        let diff = abs(transitCoordinate.longitude - natalCoordinate.longitude)
        return diff > 180 ? 360 - diff : diff
    }
}

/// Convenience extension for easy chart creation
public extension NatalChart {
    
    /// Create a transit chart for this natal chart
    /// - Parameters:
    ///   - date: The date for transit calculations
    ///   - aspectOrb: Orb in degrees for aspect calculations (default: 8.0)
    /// - Returns: A transit chart
    func transitChart(for date: Date, aspectOrb: Double = 8.0) -> TransitChart {
        return TransitChart(natalChart: self, transitDate: date, aspectOrb: aspectOrb)
    }
}
