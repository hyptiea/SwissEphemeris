//
//  Asteroid.swift
//  
//
//  Created by Vincent Smithers on 13.02.21.
//

import Foundation
import CSwissEphemeris

/// Models an asteroid.
public struct Asteroid: CelestialBody, Hashable {
    public static var allCases: [Asteroid] = [
        .chiron,
        .pholus,
        .ceres,
        .pallas,
        .juno,
        .vesta,
        .hygiea
    ]

    public let name: String
    public let value: Int32
    
    public init(name: String, value: Int32) {
        self.name = name
        self.value = value
    }
    
    /// Creates an `Asteroid` instance for a numbered asteroid from the Minor Planet Center catalog.
    /// - Parameters:
    ///   - number: The Minor Planet Center number for the asteroid.
    ///   - name: The name of the asteroid.
    /// - Returns: An `Asteroid` instance.
    public static func numbered(_ number: Int32, name: String) -> Asteroid {
        return Asteroid(name: name, value: SE_AST_OFFSET + number)
    }
}

// MARK: - Predefined Asteroids
public extension Asteroid {
    static let chiron = Asteroid(name: "Chiron", value: SE_CHIRON)
    static let pholus = Asteroid(name: "Pholus", value: SE_PHOLUS)
    static let ceres = Asteroid(name: "Ceres", value: SE_CERES)
    static let pallas = Asteroid(name: "Pallas", value: SE_PALLAS)
    static let juno = Asteroid(name: "Juno", value: SE_JUNO)
    static let hygiea = Asteroid.numbered(10, name: "Hygiea")
    static let mimosa = Asteroid.numbered(1079, name: "Mimosa")
    static let vesta = Asteroid(name: "Vesta", value: SE_VESTA)
}
