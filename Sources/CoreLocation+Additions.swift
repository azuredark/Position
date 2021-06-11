//
//  Position+CLLocation.swift
//
//  Created by patrick piemonte on 3/1/15.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015-present patrick piemonte (http://patrickpiemonte.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import CoreLocation

extension CLLocationManager {

    public static var backgroundCapabilitiesEnabled: Bool {
         guard let capabilities = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] else {
             return false
         }
         return capabilities.contains("location")
     }

}

extension CLLocation {

    /// Radius of the Earth in meters. 6,371,000m.
    public static let earthRadiusInMeters = Double(6371e3)

    /// Calculates the location coordinate for a given bearing and distance from this location as origin.
    ///
    /// - Parameters:
    ///   - bearingDegrees: Bearing in degrees
    ///   - distanceMeters: Distance in meters
    ///   - origin: Coordinate from which the result is calculated
    /// - Returns: Location coordinate at the bearing and distance from origin coordinate.
    public func locationCoordinate(withBearing bearingDegrees: Double, distanceMeters: Double) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6)

        let rbearing = bearingDegrees * .pi / 180

        let lat1 = self.coordinate.latitude * .pi / 180
        let lon1 = self.coordinate.longitude * .pi / 180

        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(rbearing))
        let lon2 = lon1 + atan2(sin(rbearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: (lat2 * 180 / .pi), longitude: (lon2 * 180 / .pi))
    }

    /// Calculate the bearing to another location
    /// - Parameter toLocation: target location
    /// - Returns: Bearing in degrees.
    public func bearing(toLocation: CLLocation) -> CLLocationDirection {
        let fromLat = Measurement(value: self.coordinate.latitude, unit: UnitAngle.degrees).converted(to: .radians).value
        let fromLon = Measurement(value: self.coordinate.longitude, unit: UnitAngle.degrees).converted(to: .radians).value

        let toLat = Measurement(value: toLocation.coordinate.latitude, unit: UnitAngle.degrees).converted(to: .radians).value
        let toLon = Measurement(value: toLocation.coordinate.longitude, unit: UnitAngle.degrees).converted(to: .radians).value

        let y = sin(toLon - fromLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(toLon - fromLon)

        var bearingInDegrees: CLLocationDirection = Measurement(value: atan2(y, x), unit: UnitAngle.radians).converted(to: .degrees).value as CLLocationDirection
        bearingInDegrees = (bearingInDegrees + 360.0).truncatingRemainder(dividingBy: 360.0)

        return bearingInDegrees
    }

}

extension CLLocation {

    /// Creates a Virtual Contact File (VCF) or vCard for the location.
    ///
    /// - Returns: Local file path URL.
    public func vCard(name: String = "Location") -> URL? {
        guard let cachesPathString = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }

        guard CLLocationCoordinate2DIsValid(self.coordinate) else {
            return nil
        }

        let vCardString = [
            "BEGIN:VCARD",
            "VERSION:3.0",
            "N:;\(name);;;",
            "FN:\(name)",
            "item1.URL;type=pref:http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)",
            "item1.X-ABLabel:map url",
            "END:VCARD"
            ].joined(separator: "\n")

        let vCardFilePath = (cachesPathString as NSString).appendingPathComponent("\(name).loc.vcf")
        do {
            try vCardString.write(toFile: vCardFilePath, atomically: true, encoding: String.Encoding.utf8)
        } catch let error {
            print("error, \(error), saving vCard \(vCardString) to file path \(vCardFilePath)")
        }

        return URL(fileURLWithPath: vCardFilePath)
    }

}
