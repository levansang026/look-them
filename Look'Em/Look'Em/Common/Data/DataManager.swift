//
//  DataManager.swift
//  Look'Em
//
//  Created by Welcome on 12/16/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleMaps
import GooglePlaces


public protocol DataManagerDelegate: class  {
    func dataManager(didUpdate location: NHLocation)
    func dataDidLoad()
    func dataManager(didGet routes: [[String: AnyObject]])
}

class DataManager: NSObject {
    
    var firstLoad: Bool = true
    static let shared = DataManager()
    var locationManager = CLLocationManager()
    var myLocation = NHLocation(latitude: 0.0, longitude: 0.0)
    var persons = [Person]()
    
    weak var delegate: DataManagerDelegate?
    
    override init() {
        super.init()
    }
    
    fileprivate func getCurrentLocation() {
        locationManager.delegate = self
        locationManager.distanceFilter = 1
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
    }
    
    
    fileprivate func convertData(completionHandler: (_ result: AnyObject?, _ error: NSError?)->Void) {
        
        guard let path = Bundle.main.path(forResource: "nears", ofType: "json") else {
            let userInfo = [NSLocalizedDescriptionKey: "Could not load json file"]
            return completionHandler(nil, NSError(domain: "load data file", code: 1, userInfo: userInfo))
        }
        
        var parsedResult: AnyObject! = nil
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON"]
            completionHandler(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandler(parsedResult, nil)
    }
    
    func requestCurrentLocation() {
        getCurrentLocation()
    }
    
    func loadData() -> [Person] {
        self.convertData { (result, error) in
            
            guard error == nil else {
                return
            }
            
            guard let res = result as? [String: AnyObject] else {
                return
            }
            
            guard let personArr = res["persons"] as? [[String: AnyObject]] else {
                return
            }
            
            personArr.forEach({ person in
                let id = person["id"] as! Int
                let name = person["name"] as! String
                let age = person["age"] as! Int
                let sex = person["sex"] as! Int == 1 ? Sex.male : Sex.female
                let avatar = person["avatar"] as! String
                let latitude = person["latitude"] as! Double
                let longitude = person["longitude"] as! Double
                let status = person["status"] as! String
                let distance = NHLocation(latitude: latitude, longitude: longitude).disTance(to: DataManager.shared.myLocation)
                let person = Person(id: id, name: name, imageURLString: avatar, location: NHLocation(latitude: latitude, longitude: longitude), distance: distance, age: age, sex: sex, status: status)
                persons.append(person)
            })
            
        }
        
        return persons
    }
}

extension DataManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let curCoordinate = locations.last?.coordinate
        self.myLocation = NHLocation(latitude: (curCoordinate?.latitude)!, longitude: (curCoordinate?.longitude)!)
        if firstLoad {
            persons = loadData()
            firstLoad = false
            delegate?.dataDidLoad()
        }
        delegate?.dataManager(didUpdate: myLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension DataManager {
    func drawPath(endLocation: NHLocation)
    {
        let origin = "\(DataManager.shared.myLocation.latitude),\(DataManager.shared.myLocation.longitude)"
        let destination = "\(endLocation.latitude),\(endLocation.longitude)"
        
        let urlStr = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=AIzaSyB06I8TdrlnUy3aIT71b7eSYokaF-TWKGU"
        let url = URL(string: urlStr)
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject] {
                    
                    // handle json...
                    guard let routes = json["routes"] as? [[String: AnyObject]] else {
                        return
                    }
                    
                    self.delegate?.dataManager(didGet: routes)
                    
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
}
