//
//  Person.swift
//  Look'Em
//
//  Created by Le Vu Hoai An on 12/16/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import Foundation
import UIKit

enum Sex {
    case male, female
    
    var icon: UIImage {
        switch self {
        case .female:
            return UIImage(named: "female-ico")!
        case .male:
            return UIImage(named: "male-ico")!
        }
    }
    
    var value: String {
        switch self {
        case .female:
            return "nữ"
        case .male:
            return "nam"
        }
    }
}

class Person {
    
    var personID: Int?
    var name: String?
    var location: NHLocation?
    var imageURLString: String?
    var sex: Sex?
    var age: Int?
    var status: String?
    var distance: Double?
    
    init(id: Int, name: String, imageURLString: String, location: NHLocation, distance: Double, age: Int, sex: Sex, status: String) {
        self.personID = id
        self.name = name
        self.imageURLString = imageURLString
        self.location = location
        self.age = age
        self.sex = sex
        self.status = status
        self.distance = distance
    }
}
