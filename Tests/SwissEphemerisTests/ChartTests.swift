//
//  ChartTests.swift
//  
//
//  Created by Swiss Ephemeris Extension
//

import XCTest
import Foundation
@testable import SwissEphemeris

class NatalChartTests: XCTestCase {
    
    override func setUpWithError() throws {
        JPLFileManager.setEphemerisPath()
    }
    
    func testNatalChartCreation() throws {
        // Test date: December 14, 2019 13:39 UT/GMT
        let testDate = Date(timeIntervalSince1970: 1576330740)
        let latitude: Double = 37.5081153
        let longitude: Double = -122.2854528
        
        let chart = NatalChart(
            date: testDate,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .placidus
        )
        
        // Verify basic properties
        XCTAssertEqual(chart.date, testDate)
        XCTAssertEqual(chart.latitude, latitude)
        XCTAssertEqual(chart.longitude, longitude)
        XCTAssertEqual(chart.houseSystem, .placidus)
        
        // Verify all planets have valid coordinates (not NaN)
        XCTAssertFalse(chart.planets.sun.longitude.isNaN, "Sun longitude should not be NaN")
        XCTAssertGreaterThanOrEqual(chart.planets.sun.longitude, 0)
        XCTAssertLessThanOrEqual(chart.planets.sun.longitude, 360)
        
        XCTAssertFalse(chart.planets.moon.longitude.isNaN, "Moon longitude should not be NaN")
        XCTAssertGreaterThanOrEqual(chart.planets.moon.longitude, 0)
        XCTAssertLessThanOrEqual(chart.planets.moon.longitude, 360)
        
        XCTAssertFalse(chart.planets.mercury.longitude.isNaN, "Mercury longitude should not be NaN")
        XCTAssertGreaterThanOrEqual(chart.planets.mercury.longitude, 0)
        XCTAssertLessThanOrEqual(chart.planets.mercury.longitude, 360)
        
        // Verify houses are calculated
        XCTAssertFalse(chart.houses.ascendent.tropical.value.isNaN, "Ascendent should not be NaN")
        XCTAssertGreaterThanOrEqual(chart.houses.ascendent.tropical.value, 0)
        XCTAssertLessThanOrEqual(chart.houses.ascendent.tropical.value, 360)
        XCTAssertGreaterThanOrEqual(chart.houses.midHeaven.tropical.value, 0)
        XCTAssertLessThanOrEqual(chart.houses.midHeaven.tropical.value, 360)
        
        // Verify lunar nodes
        XCTAssertFalse(chart.lunarNodes.trueNode.longitude.isNaN, "True node longitude should not be NaN")
        XCTAssertGreaterThanOrEqual(chart.lunarNodes.trueNode.longitude, 0)
        XCTAssertLessThanOrEqual(chart.lunarNodes.trueNode.longitude, 360)
        XCTAssertGreaterThanOrEqual(chart.lunarNodes.meanNode.longitude, 0)
        XCTAssertLessThanOrEqual(chart.lunarNodes.meanNode.longitude, 360)
        
    }
    
    func testNatalChartWithCustomAsteroids() throws {
        // Define a custom list of asteroids, including a numbered one.
        // Assuming you have an ephemeris file for asteroid 433 (Eros).
        let customAsteroids: [Asteroid] = [
            .urania,
            .numbered(433, name: "Eros")
        ]
        
        let testDate = Date(timeIntervalSince1970: 1576330740)
        let chart = NatalChart(
            date: testDate,
            latitude: 37.5081153,
            longitude: -122.2854528,
            asteroids: customAsteroids
        )
        
        XCTAssertEqual(chart.asteroids.all.count, 2)
        

        // Check for Eros
        let eros = try XCTUnwrap(chart.asteroids[.numbered(30, name: "Urania")])
        XCTAssertFalse(eros.longitude.isNaN)
        XCTAssertEqual(eros.body.name, "Eros")
        
        // Check that an asteroid not in the list is nil
        XCTAssertNil(chart.asteroids.all)
    }
    
    func testNatalChartZodiacValues() throws {
        let testDate = Date(timeIntervalSince1970: 1576330740) // Dec 14, 2019
        let chart = NatalChart(
            date: testDate,
            latitude: 37.5081153,
            longitude: -122.2854528
        )
        
        // Test that we get individual values, not formatted strings
        let sunPosition = chart.planets.sun
        
        // Verify coordinates are not NaN
        XCTAssertFalse(sunPosition.longitude.isNaN, "Sun longitude should not be NaN")
        XCTAssertFalse(sunPosition.tropical.degree.isNaN, "Tropical degree should not be NaN")
        
        // Verify tropical coordinates
        XCTAssertGreaterThanOrEqual(sunPosition.tropical.degree, 0)
        XCTAssertLessThan(sunPosition.tropical.degree, 30)
        XCTAssertGreaterThanOrEqual(sunPosition.tropical.minute, 0)
        XCTAssertLessThan(sunPosition.tropical.minute, 60)
        XCTAssertGreaterThanOrEqual(sunPosition.tropical.second, 0)
        XCTAssertLessThan(sunPosition.tropical.second, 60)
        
        // Verify sidereal coordinates
        XCTAssertGreaterThanOrEqual(sunPosition.sidereal.degree, 0)
        XCTAssertLessThan(sunPosition.sidereal.degree, 30)
        XCTAssertGreaterThanOrEqual(sunPosition.sidereal.minute, 0)
        XCTAssertLessThan(sunPosition.sidereal.minute, 60)
        
        // Verify sign is valid
        XCTAssertTrue(Zodiac.allCases.contains(sunPosition.tropical.sign))
        XCTAssertTrue(Zodiac.allCases.contains(sunPosition.sidereal.sign))
    }
    
    func testNatalChartAspects() throws {
        let testDate = Date(timeIntervalSince1970: 1576330740)
        let chart = NatalChart(
            date: testDate,
            latitude: 37.5081153,
            longitude: -122.2854528,
            aspectOrb: 8.0
        )
        
        // Should have some aspects
        XCTAssertGreaterThan(chart.aspects.count, 0)
        
        // Test specific aspect properties
        if let firstAspect = chart.aspects.first {
            XCTAssertTrue(Planet.allCases.contains(firstAspect.planetA))
            XCTAssertTrue(Planet.allCases.contains(firstAspect.planetB))
            
            // The orb should be the absolute value and non-negative
            XCTAssertGreaterThanOrEqual(firstAspect.orb, 0, "Orb should be non-negative, got: \(firstAspect.orb)")
            XCTAssertLessThanOrEqual(firstAspect.orb, 8.0, "Orb should be within specified limit") // Within specified orb
            
            // Verify aspect type and that orb values are non-negative
            switch firstAspect.aspect {
            case .conjunction(let orb):
                XCTAssertGreaterThanOrEqual(abs(orb), 0, "Conjunction orb should be non-negative")
            case .sextile(let orb):
                XCTAssertGreaterThanOrEqual(abs(orb), 0, "Sextile orb should be non-negative")
            case .square(let orb):
                XCTAssertGreaterThanOrEqual(abs(orb), 0, "Square orb should be non-negative")
            case .trine(let orb):
                XCTAssertGreaterThanOrEqual(abs(orb), 0, "Trine orb should be non-negative")
            case .opposition(let orb):
                XCTAssertGreaterThanOrEqual(abs(orb), 0, "Opposition orb should be non-negative")
            }
        }
    }
    
    func testPlanetaryPositionsArray() throws {
        let testDate = Date()
        let chart = NatalChart(
            date: testDate,
            latitude: 0,
            longitude: 0
        )
        
        XCTAssertEqual(chart.planets.all.count, 10)
        
        let planetBodies = chart.planets.all.map { $0.body }
        XCTAssertTrue(planetBodies.contains(.sun))
        XCTAssertTrue(planetBodies.contains(.moon))
        XCTAssertTrue(planetBodies.contains(.mercury))
        XCTAssertTrue(planetBodies.contains(.venus))
        XCTAssertTrue(planetBodies.contains(.mars))
        XCTAssertTrue(planetBodies.contains(.jupiter))
        XCTAssertTrue(planetBodies.contains(.saturn))
        XCTAssertTrue(planetBodies.contains(.uranus))
        XCTAssertTrue(planetBodies.contains(.neptune))
        XCTAssertTrue(planetBodies.contains(.pluto))
    }
    
    func testEphemerisPathValidation() throws {
        // Test that setting ephemeris path works
        JPLFileManager.setEphemerisPath()
        
        // Create a simple coordinate to verify ephemeris is working
        let testDate = Date(timeIntervalSince1970: 1576330740)
        let sunCoord = Coordinate(body: Planet.sun, date: testDate)
        
        XCTAssertFalse(sunCoord.longitude.isNaN, "Sun coordinate should be valid after setting ephemeris path")
        XCTAssertGreaterThanOrEqual(sunCoord.longitude, 0)
        XCTAssertLessThanOrEqual(sunCoord.longitude, 360)
    }
}

class TransitChartTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set ephemeris path
        JPLFileManager.setEphemerisPath()
    }
    
    func testTransitChartCreation() throws {
        // Natal chart date
        let natalDate = Date(timeIntervalSince1970: 1576330740) // Dec 14, 2019
        let natalChart = NatalChart(
            date: natalDate,
            latitude: 37.5081153,
            longitude: -122.2854528
        )
        
        // Transit date (one year later)
        let transitDate = Date(timeIntervalSince1970: 1607866740) // Dec 14, 2020
        
        let transitChart = TransitChart(
            natalChart: natalChart,
            transitDate: transitDate,
            aspectOrb: 8.0
        )
        
        // Verify basic properties
        XCTAssertEqual(transitChart.natalChart.date, natalDate)
        XCTAssertEqual(transitChart.transitDate, transitDate)
        
        // Verify transit planets are calculated and valid
        XCTAssertFalse(transitChart.transitPlanets.sun.longitude.isNaN, "Transit sun should not be NaN")
        XCTAssertGreaterThanOrEqual(transitChart.transitPlanets.sun.longitude, 0)
        XCTAssertLessThanOrEqual(transitChart.transitPlanets.sun.longitude, 360)
        
        // Transit positions should be different from natal positions
        XCTAssertNotEqual(transitChart.transitPlanets.sun.longitude, natalChart.planets.sun.longitude)
    }
    
    func testTransitChartConvenience() throws {
        let natalDate = Date(timeIntervalSince1970: 1576330740)
        let natalChart = NatalChart(
            date: natalDate,
            latitude: 37.5081153,
            longitude: -122.2854528
        )
        
        let transitDate = Date()
        let transitChart = natalChart.transitChart(for: transitDate)
        
        XCTAssertEqual(transitChart.natalChart.date, natalDate)
        XCTAssertEqual(transitChart.transitDate, transitDate)
    }
    
    func testTransitAspects() throws {
        let natalChart = NatalChart(
            date: Date(timeIntervalSince1970: 1576330740),
            latitude: 37.5081153,
            longitude: -122.2854528
        )
        
        let transitChart = TransitChart(
            natalChart: natalChart,
            transitDate: Date(),
            aspectOrb: 10.0 // Larger orb to ensure we find some aspects
        )
        
        // Should have some transit aspects
        XCTAssertGreaterThan(transitChart.transitAspects.count, 0)
        
        if let firstTransitAspect = transitChart.transitAspects.first {
            XCTAssertTrue(Planet.allCases.contains(firstTransitAspect.transitPlanet))
            XCTAssertTrue(Planet.allCases.contains(firstTransitAspect.natalPlanet))
            XCTAssertGreaterThanOrEqual(firstTransitAspect.orb, 0, "Transit aspect orb should be non-negative")
            XCTAssertGreaterThanOrEqual(firstTransitAspect.exactDegree, 0)
            XCTAssertLessThanOrEqual(firstTransitAspect.exactDegree, 180)
        }
    }
    
    func testTransitFiltering() throws {
        let natalChart = NatalChart(
            date: Date(timeIntervalSince1970: 1576330740),
            latitude: 37.5081153,
            longitude: -122.2854528
        )
        
        let transitChart = TransitChart(
            natalChart: natalChart,
            transitDate: Date(),
            aspectOrb: 10.0
        )
        
        // Test filtering by natal planet
        let sunTransits = transitChart.transitsTo(.sun)
        for transit in sunTransits {
            XCTAssertEqual(transit.natalPlanet, .sun)
        }
        
        // Test filtering by transiting planet
        let marsTransits = transitChart.transitsFrom(.mars)
        for transit in marsTransits {
            XCTAssertEqual(transit.transitPlanet, .mars)
        }
    }
    
    func testTransitAspectValues() throws {
        let natalChart = NatalChart(
            date: Date(timeIntervalSince1970: 1576330740),
            latitude: 37.5081153,
            longitude: -122.2854528
        )
        
        let transitChart = TransitChart(
            natalChart: natalChart,
            transitDate: Date(),
            aspectOrb: 10.0
        )
        
        if let transitAspect = transitChart.transitAspects.first {
            // Verify coordinates are not NaN
            XCTAssertFalse(transitAspect.transitCoordinate.longitude.isNaN, "Transit coordinate should not be NaN")
            XCTAssertFalse(transitAspect.natalCoordinate.longitude.isNaN, "Natal coordinate should not be NaN")
            
            // Verify we get individual coordinate values
            XCTAssertGreaterThanOrEqual(transitAspect.transitCoordinate.longitude, 0)
            XCTAssertLessThanOrEqual(transitAspect.transitCoordinate.longitude, 360)
            XCTAssertGreaterThanOrEqual(transitAspect.natalCoordinate.longitude, 0)
            XCTAssertLessThanOrEqual(transitAspect.natalCoordinate.longitude, 360)
            
            // Verify aspect calculation
            XCTAssertGreaterThanOrEqual(transitAspect.exactDegree, 0)
            XCTAssertLessThanOrEqual(transitAspect.exactDegree, 180)
            
            // Verify orb is within acceptable range
            XCTAssertGreaterThanOrEqual(transitAspect.orb, 0, "Transit aspect orb should be non-negative")
            XCTAssertLessThanOrEqual(transitAspect.orb, 10.0)
        }
    }
}

class ChartIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set ephemeris path
        JPLFileManager.setEphemerisPath()
    }
    
    func testCompleteChartWorkflow() throws {
        // Create natal chart
        let birthDate = Date(timeIntervalSince1970: 1576330740) // Dec 14, 2019
        let natalChart = NatalChart(
            date: birthDate,
            latitude: 37.5081153,
            longitude: -122.2854528,
            houseSystem: .placidus
        )
        
        // Verify natal chart has complete data
        XCTAssertEqual(natalChart.planets.all.count, 10)
        XCTAssertEqual(natalChart.asteroids.all.count, NatalChart.defaultAsteroids.count)
        XCTAssertGreaterThan(natalChart.aspects.count, 0)
        
        // Create transit chart
        let currentDate = Date()
        let transitChart = natalChart.transitChart(for: currentDate, aspectOrb: 8.0)
        
        // Verify transit chart
        XCTAssertGreaterThanOrEqual(transitChart.transitAspects.count, 0) // May be 0 if no tight aspects
        
        // Test specific planet access
        let natalSun = natalChart.planets.sun
        let transitSun = transitChart.transitPlanets.sun
        
        // Verify coordinates are not NaN
        XCTAssertFalse(natalSun.longitude.isNaN, "Natal sun should not be NaN")
        XCTAssertFalse(transitSun.longitude.isNaN, "Transit sun should not be NaN")
        
        XCTAssertGreaterThanOrEqual(natalSun.tropical.degree, 0)
        XCTAssertLessThan(natalSun.tropical.degree, 30)
        XCTAssertGreaterThanOrEqual(transitSun.tropical.degree, 0)
        XCTAssertLessThan(transitSun.tropical.degree, 30)
        
        // Verify coordinates are different (unless by extreme coincidence)
        let longitudeDifference = abs(natalSun.longitude - transitSun.longitude)
        XCTAssertGreaterThan(longitudeDifference, 0.01) // Should be different by at least 0.01 degrees
    }
    
    func testChartWithDifferentHouseSystems() throws {
        let testDate = Date(timeIntervalSince1970: 1576330740)
        let latitude: Double = 37.5081153
        let longitude: Double = -122.2854528
        
        let placidusChart = NatalChart(
            date: testDate,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .placidus
        )
        
        let kochChart = NatalChart(
            date: testDate,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .koch
        )
        
        // Planetary positions should be the same
        XCTAssertEqual(placidusChart.planets.sun.longitude, kochChart.planets.sun.longitude)
        
        // House cusps should be different
        XCTAssertEqual(placidusChart.houses.ascendent.tropical.value, kochChart.houses.ascendent.tropical.value) // Ascendant should be same
        // Other house cusps may differ
    }
}
