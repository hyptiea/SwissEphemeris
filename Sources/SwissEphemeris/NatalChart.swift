//
//  NatalChart.swift
//  
//
//  Created by Swiss Ephemeris Extension
//

import Foundation

/// A complete natal chart containing planetary positions, house cusps, and aspects.
public struct NatalChart {
    
    /// The list of asteroids to include in chart calculations.
    /// Defaults to Chiron, Ceres, Pallas, Juno, Vesta, and Pholus.
    public static var defaultAsteroids: [Asteroid] = [
        .melpomene,
        .calliope,
        .thalia,
        .euterpe,
        .urania,
        .polyhymnia,
        .erato,
        .terpsichore,
        .clio,
        .chiron
    ]
    
    /// The birth date and time
    public let date: Date
    
    /// The birth location latitude
    public let latitude: Double
    /// The birth location longitude
    public let longitude: Double
    
    /// The house system used for calculations
    public let houseSystem: HouseSystem
    
    /// All planetary coordinates
    public let planets: PlanetaryPositions
    
    /// All house cusps including angles
    public let houses: HouseCusps
    
    /// All major aspects between planets
    public let aspects: [AspectInfo]
    
    /// Lunar nodes
    public let lunarNodes: LunarNodePositions
    
    /// Major asteroids
    public let asteroids: AsteroidPositions
    
    /// Creates a natal chart for the given birth data
    /// - Parameters:
    ///   - date: Birth date and time
    ///   - latitude: Birth location latitude
    ///   - longitude: Birth location longitude
    ///   - houseSystem: House system to use (default: .placidus)
    ///   - aspectOrb: Orb in degrees for aspect calculations (default: 8.0)
    ///   - asteroids: A list of asteroids to include in the chart.
    public init(date: Date,
                latitude: Double,
                longitude: Double,
                houseSystem: HouseSystem = .placidus,
                aspectOrb: Double = 8.0,
                asteroids: [Asteroid] = NatalChart.defaultAsteroids) {
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
        self.houseSystem = houseSystem
        
        // Calculate planetary positions
        self.planets = PlanetaryPositions(date: date)
        
        // Calculate house cusps
        self.houses = HouseCusps(date: date, latitude: latitude, longitude: longitude, houseSystem: houseSystem)
        
        // Calculate lunar nodes
        self.lunarNodes = LunarNodePositions(date: date)
        
        // Calculate asteroids
        self.asteroids = AsteroidPositions(date: date, asteroids: asteroids)
        
        // Calculate aspects between all planets
        var calculatedAspects: [AspectInfo] = []
        let allPlanets = Planet.allCases
        
        for i in 0..<allPlanets.count {
            for j in (i+1)..<allPlanets.count {
                let planetA = allPlanets[i]
                let planetB = allPlanets[j]
                let pair = Pair(a: planetA, b: planetB)
                
                if let aspect = Aspect(pair: pair, date: date, orb: aspectOrb) {
                    calculatedAspects.append(AspectInfo(
                        planetA: planetA,
                        planetB: planetB,
                        aspect: aspect,
                        orb: aspect.remainder
                    ))
                }
            }
        }
        
        self.aspects = calculatedAspects
    }
}

/// Contains all planetary positions with individual coordinate access
public struct PlanetaryPositions {
    public let sun: Coordinate<Planet>
    public let moon: Coordinate<Planet>
    public let mercury: Coordinate<Planet>
    public let venus: Coordinate<Planet>
    public let mars: Coordinate<Planet>
    public let jupiter: Coordinate<Planet>
    public let saturn: Coordinate<Planet>
    public let uranus: Coordinate<Planet>
    public let neptune: Coordinate<Planet>
    public let pluto: Coordinate<Planet>
    
    /// All planets as an array for iteration
    public var all: [Coordinate<Planet>] {
        [sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto]
    }
    
    internal init(date: Date) {
        self.sun = Coordinate(body: .sun, date: date)
        self.moon = Coordinate(body: .moon, date: date)
        self.mercury = Coordinate(body: .mercury, date: date)
        self.venus = Coordinate(body: .venus, date: date)
        self.mars = Coordinate(body: .mars, date: date)
        self.jupiter = Coordinate(body: .jupiter, date: date)
        self.saturn = Coordinate(body: .saturn, date: date)
        self.uranus = Coordinate(body: .uranus, date: date)
        self.neptune = Coordinate(body: .neptune, date: date)
        self.pluto = Coordinate(body: .pluto, date: date)
    }

    /// Determines the house of a specific planet given a set of house cusps and house system.
    /// - Parameters:
    ///   - planet: The planet for which to find the house.
    ///   - houseCusps: The calculated house cusps for the chart.
    ///   - system: The house system to use.
    /// - Returns: The house number (1-12) the planet is in, or nil if not found.
    public func house(of planet: Planet, in houseCusps: HouseCusps, system: HouseSystem) -> Int? {
        guard let planetCoordinate = self.all.first(where: { $0.body == planet }) else {
            return nil
        }
        switch system {
        case .wholeSign:
            let ascLongitude = houseCusps.ascendent.tropical.value
            let ascSignIndex = Int(floor(ascLongitude / 30.0)) % 12
            let planetSignIndex = Int(floor(planetCoordinate.tropical.value / 30.0)) % 12
            let idx = (planetSignIndex - ascSignIndex + 12) % 12
            return idx + 1
        default:
            return houseCusps.house(for: planetCoordinate.longitude)
        }
    }
}

/// Contains lunar node positions
public struct LunarNodePositions {
    public let trueNode: Coordinate<LunarNorthNode>
    public let meanNode: Coordinate<LunarNorthNode>
    
    internal init(date: Date) {
        self.trueNode = Coordinate(body: .trueNode, date: date)
        self.meanNode = Coordinate(body: .meanNode, date: date)
    }
}

/// Contains calculated asteroid positions
public struct AsteroidPositions {
    private let positions: [Asteroid: Coordinate<Asteroid>]

    /// All asteroids as an array for iteration
    public var all: [Coordinate<Asteroid>] {
        Array(positions.values)
    }
    
    /// Access asteroid position by its definition.
    public subscript(asteroid: Asteroid) -> Coordinate<Asteroid>? {
        return positions[asteroid]
    }
    
    internal init(date: Date, asteroids: [Asteroid]) {
        var calculatedPositions = [Asteroid: Coordinate<Asteroid>]()
        asteroids.forEach {
            calculatedPositions[$0] = Coordinate(body: $0, date: date)
        }
        self.positions = calculatedPositions
    }

    /// Determines the house of a specific asteroid given a set of house cusps and house system.
    /// - Parameters:
    ///   - asteroid: The asteroid for which to find the house.
    ///   - houseCusps: The calculated house cusps for the chart.
    ///   - system: The house system to use.
    /// - Returns: The house number (1-12) the asteroid is in, or nil if not found.
    public func house(of asteroid: Asteroid, in houseCusps: HouseCusps, system: HouseSystem) -> Int? {
        guard let asteroidCoordinate = self.all.first(where: { $0.body == asteroid }) else {
            return nil
        }
        switch system {
        case .wholeSign:
            let ascLongitude = houseCusps.ascendent.tropical.value
            let ascSignIndex = Int(floor(ascLongitude / 30.0)) % 12
            let asteroidSignIndex = Int(floor(asteroidCoordinate.tropical.value / 30.0)) % 12
            let idx = (asteroidSignIndex - ascSignIndex + 12) % 12
            return idx + 1
        default:
            return houseCusps.house(for: asteroidCoordinate.longitude)
        }
    }
}

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

