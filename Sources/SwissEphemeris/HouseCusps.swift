//
//  HouseCusps.swift
//  
//
//  26.12.19.
//

import CSwissEphemeris
import Foundation

/// Models a house system with a `Cusp` for each house, ascendent and midheaven.
public struct HouseCusps {

    /// The time at which the house system is valid
    public let date: Date
    /// The pointer passed into `set_house_system(julianDate, latitude, longitude, ascendentPointer, cuspPointer)`
    /// `ascPointer` argument
    private let ascendentPointer = UnsafeMutablePointer<Double>.allocate(capacity: 10)
    /// The pointer passed into `set_house_system(julianDate, latitude, longitude, ascendentPointer, cuspPointer)`
    /// `cuspPointer` argument
    /// This is not used because it is not relevant to ascendent data
    private let cuspPointer = UnsafeMutablePointer<Double>.allocate(capacity: 13)
    /// Point of ascendent
	public let ascendent: Cusp
    /// Point of MC
    public let midHeaven: Cusp
    /// Cusp between twelth and first house
    public let first: Cusp
    /// Cusp between first and second house
    public let second: Cusp
    /// Cusp between second and third house
    public let third: Cusp
    /// Cusp between third and fourth house
    public let fourth: Cusp
    /// Cusp between fourth and fifth house
    public let fifth: Cusp
    /// Cusp between fifth and sixth house
    public let sixth: Cusp
    /// Cusp between sixth and seventh house
    public let seventh: Cusp
    /// Cusp between seventh and eighth house
    public let eighth: Cusp
    /// Cusp between eighth and ninth house
    public let ninth: Cusp
    /// Cusp between the ninth and tenth house
    public let tenth: Cusp
    /// Cusp between the tenth and eleventh house
    public let eleventh: Cusp
    /// Cusp between the eleventh and twelfth house
    public let twelfth: Cusp

    // Properties to store chart details for house calculation
    private let chartLatitude: Double
    private let chartLongitude: Double
    private let chartHouseSystem: HouseSystem
    private let chartJulianDate: Double
    private let eclipticObliquity: Double // Need this from the swe_houses calculation

	/// The preferred initializer
	/// - Parameters:
	///   - date: The date for the houses to be laid out
	///   - latitude: The location latitude for the house system
	///   - longitude: The locations longitude for the house system
	///   - houseSystem: The type of `HouseSystem`.
    public init(date: Date,
                latitude: Double,
				longitude: Double,
				houseSystem: HouseSystem) {

        self.date = date
        self.chartLatitude = latitude
        self.chartLongitude = longitude
        self.chartHouseSystem = houseSystem
        self.chartJulianDate = date.julianDate()

        // Allocate a buffer for the ecliptic obliquity, which is often calculated
        // internally by swe_houses_ex2 or equivalent for the current date.
        // For simplicity, we'll calculate it once here.
        var nutlo = (0.0, 0.0) // nutation longitude and obliquity in degrees
        let tjde = date.julianDate() + swe_deltat(date.julianDate())
        var eps_mean = swi_epsiln(tjde, 0)
        swi_nutation(tjde, 0, &nutlo.0)
        self.eclipticObliquity = (eps_mean + nutlo.1) * (180.0 / .pi) // Convert to degrees

		defer {
			cuspPointer.deallocate()
			ascendentPointer.deallocate()
		}
		swe_houses(date.julianDate(), latitude, longitude, houseSystem.rawValue, cuspPointer, ascendentPointer);
		ascendent = Cusp(value: ascendentPointer[0], date: date)
		midHeaven = Cusp(value: ascendentPointer[1], date: date)
		first = Cusp(value: cuspPointer[1], date: date)
		second = Cusp(value: cuspPointer[2], date: date)
		third = Cusp(value: cuspPointer[3], date: date)
		fourth =  Cusp(value: cuspPointer[4], date: date)
		fifth = Cusp(value: cuspPointer[5], date: date)
		sixth = Cusp(value: cuspPointer[6], date: date)
		seventh = Cusp(value: cuspPointer[7], date: date)
		eighth =  Cusp(value: cuspPointer[8], date: date)
		ninth =  Cusp(value: cuspPointer[9], date: date)
		tenth = Cusp(value: cuspPointer[10], date: date)
		eleventh = Cusp(value: cuspPointer[11], date: date)
		twelfth =  Cusp(value: cuspPointer[12], date: date)
    }

    /// Determines the house number for a given ecliptic longitude.
    /// - Parameter longitude: The ecliptic longitude of the celestial body.
    /// - Returns: The house number (1-12) the longitude falls into, or `nil` if an error occurs.
    public func house(for longitude: Double) -> Int? {
        var armc: Double = 0.0 // Right Ascension of the Midheaven
        var nutlo = (0.0, 0.0) // nutation longitude and obliquity in degrees
        
        let tjde = self.chartJulianDate + swe_deltat(self.chartJulianDate)
        var eps_mean = swi_epsiln(tjde, 0)
        swi_nutation(tjde, 0, &nutlo.0)
        
        // Calculate ARMC using swe_sidtime0, which requires UT date.
        // swe_sidtime0 takes UT (self.date.julianDate()), corrected obliquity (eps_mean + nutlo.1), and nutation in longitude (nutlo.0)
        // nutlo is in radians, so convert to degrees before adding to eps_mean, then swe_sidtime0 expects degrees.
        armc = swe_degnorm(swe_sidtime0(self.chartJulianDate, (eps_mean + nutlo.1) * (180.0 / .pi), nutlo.0 * (180.0 / .pi)) * 15 + self.chartLongitude)

        // The swe_house_pos function takes a CChar for the house system.
        // We'll pass the raw value of our HouseSystem enum.
        let hsysCChar = self.chartHouseSystem.rawValue

        var xpin: (Double, Double) = (longitude, 0.0) // Ecliptic longitude and latitude (0 for house calculation)
        var serr = "" // Buffer for error message

        // call swe_house_pos, which returns a double (house number, possibly with decimal)
        let housePos = withUnsafeMutablePointer(to: &xpin.0) { xpinPtr in
            swe_house_pos(
                armc,
                self.chartLatitude,
                self.eclipticObliquity,
                hsysCChar,
                xpinPtr,
                &serr
            )
        }

        if housePos.isNaN || housePos == 0.0 || !serr.isEmpty {
            // handle error if swe_house_pos returns an invalid result or an error message
            // In C, 0 can indicate an error or an invalid position for some house systems.
            // Check the serr for actual error messages.
            print("Error calculating house position: \(serr)")
            return nil
        }

        // Convert the double house position to an integer house number (1-12)
        // swe_house_pos returns a value from 1 to 12.999...
        return Int(ceil(housePos))
    }
}
