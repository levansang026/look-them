//
//  NHLocation.swift
//  Look'Em
//
//  Created by Welcome on 12/16/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import Foundation
import GoogleMaps
import GooglePlaces

open class NHLocation {
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    func disTance(to location: NHLocation) -> Double {
        let first = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let second = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        return first.distance(from: second).rounded()
    }
    
    func cllocation2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
