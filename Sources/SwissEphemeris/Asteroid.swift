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
    static let melpomene = Asteroid.numbered(18, name: "Melpomene")
    static let calliope = Asteroid.numbered(22, name: "Calliope")
    static let thalia = Asteroid.numbered(23, name: "Thalia")
    static let euterpe = Asteroid.numbered(27, name: "Euterpe")
    static let urania = Asteroid.numbered(30, name: "Urania")
    static let polyhymnia = Asteroid.numbered(33, name: "Polyhymnia")
    static let erato = Asteroid.numbered(62, name: "Erato")
    static let terpsichore = Asteroid.numbered(81, name: "Terpsichore")
    static let clio = Asteroid.numbered(84, name: "Clio")
    static let chiron = Asteroid.numbered(2066, name: "Chiron")


}
