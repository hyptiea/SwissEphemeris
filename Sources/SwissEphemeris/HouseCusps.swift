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
    private let armcDegrees: Double
    private let eclipticObliquityDegrees: Double

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

        // Compute ARMC and true obliquity using public Swiss Ephemeris APIs
        let tjdUT = self.chartJulianDate
        let deltaT = swe_deltat(tjdUT)
        let tjdET = tjdUT + deltaT
        // Sidereal time in hours, convert to degrees; ARMC = sidereal time (deg) + geolon (deg)
        let siderealTimeHours = swe_sidtime(tjdUT)
        let siderealTimeDegrees = siderealTimeHours * 15.0
        let rawArmc = siderealTimeDegrees + longitude
        self.armcDegrees = fmod(rawArmc.truncatingRemainder(dividingBy: 360.0) + 360.0, 360.0)
        // Get true obliquity via swe_calc_ut with SE_ECL_NUT and flags for radians; extract epsilon from xx[1]
        var xx = [Double](repeating: 0.0, count: 6)
        var serrBuffer = [CChar](repeating: 0, count: 256)
        _ = xx.withUnsafeMutableBufferPointer { xxPtr in
            swe_calc_ut(tjdUT, SE_ECL_NUT, SEFLG_SWIEPH | SEFLG_RADIANS, xxPtr.baseAddress, &serrBuffer)
        }
        let epsilonRad = xx[1] // obliquity in radians
        self.eclipticObliquityDegrees = epsilonRad * (180.0 / .pi)

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
        // The swe_house_pos function takes a CChar for the house system.
        let hsysCChar = self.chartHouseSystem.rawValue

        var xpin: (Double, Double) = (longitude, 0.0) // Ecliptic longitude and latitude (0 for house calculation)
        var serr = "" // Buffer for error message
        var charSerr = [CChar](repeating: 0, count: 256) // C-style buffer for C function

        // Copy Swift string to C-style char array
        _ = serr.utf8CString.withUnsafeBufferPointer { (ptr) in
            // Ensure we don't write more than the buffer can hold
            let count = min(ptr.count, charSerr.count - 1)
            charSerr.withUnsafeMutableBufferPointer { bufferPtr in
                _ = memcpy(bufferPtr.baseAddress, ptr.baseAddress, count)
                bufferPtr[count] = 0 // Null-terminate
            }
        }
        
        // call swe_house_pos, which returns a double (house number, possibly with decimal)
        // Ensure to pass charSerr as an UnsafeMutablePointer<CChar>
        let housePos = withUnsafeMutablePointer(to: &xpin.0) { xpinPtr in
            swe_house_pos(
                self.armcDegrees, // Use the pre-calculated ARMC degrees
                self.chartLatitude,
                self.eclipticObliquityDegrees, // Use the pre-calculated obliquity degrees
                hsysCChar,
                xpinPtr,
                &charSerr // Pass C-style error buffer
            )
        }

        // Convert C-style char array back to Swift String for inspection
        serr = String(cString: charSerr)

        if housePos.isNaN || housePos == 0.0 || !serr.filter({ $0 != "\0" }).isEmpty { // Filter null bytes before checking if empty
            // handle error if swe_house_pos returns an invalid result or an error message
            print("Error calculating house position: \(serr)")
            return nil
        }

        // Convert the double house position to an integer house number (1-12)
        // swe_house_pos returns a value from 1 to 12.999...
        return Int(ceil(housePos))
    }
}

