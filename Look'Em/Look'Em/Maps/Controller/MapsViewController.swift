//
//  MapsViewController.swift
//  Look'Em
//
//  Created by Le Vu Hoai An on 12/16/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class MapsViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    
    var curPolyLines = [GMSPolyline]()
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    var angleView: Double = 0
    var curRoutes = [[String: AnyObject]]()
    var tappedMarker: GMSMarker! {
        didSet {
            if tappedMarker != oldValue {
                for line in curPolyLines {
                    line.map = nil
                }
                curPolyLines.removeAll()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        DataManager.shared.requestCurrentLocation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DataManager.shared.delegate = self
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true;
        mapView.isBuildingsEnabled = true
        mapView.settings.myLocationButton = true
        mapView.delegate = self
        
        mapView.animate(to: GMSCameraPosition.camera(withTarget: DataManager.shared.myLocation.cllocation2D(), zoom: 18.0, bearing: 0, viewingAngle: 45))
        
        for person in DataManager.shared.persons {
            drawMarker(person: person)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    fileprivate func drawMarker(person: Person) {
        let marker = GMSMarker(position: (person.location?.cllocation2D())!)
        marker.title = person.name
        marker.snippet = person.status
        let ico = UIImage(named: "marker")?.withRenderingMode(.alwaysOriginal).changeSize(to: 60)
        let markerView = UIImageView(image: ico)
        let avatarView = UIImageView(frame: CGRect(x: 15, y: 8, width: 30, height: 30))
        avatarView.layer.cornerRadius = 15
        avatarView.clipsToBounds = true
        avatarView.image = UIImage(named: person.imageURLString!)
        markerView.addSubview(avatarView)
        marker.iconView = markerView
        marker.map = mapView
        
    }
}

extension MapsViewController: GMSMapViewDelegate {
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        DataManager.shared.requestCurrentLocation()
        CATransaction.begin()
        CAAnimation.init().duration = 1.5
        
        mapView.animate(to: GMSCameraPosition.camera(withTarget: DataManager.shared.myLocation.cllocation2D(), zoom: 18.0, bearing: 0, viewingAngle: 45))
        CATransaction.commit()
        return true
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        
        let markerView = PersonInfoView(frame: CGRect(x: 0, y: 0, width: 300, height: 80))
        
        markerView.layer.cornerRadius = 10
        markerView.layer.borderWidth = 2
        markerView.layer.borderColor = UIColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 1.0).cgColor
        markerView.clipsToBounds = true
        
        markerView.didTapHander = {
            DataManager.shared.drawPath(endLocation: NHLocation.init(latitude: marker.position.latitude, longitude: marker.position.longitude))
        }
        
        for person in DataManager.shared.persons {
            if marker.title == person.name {
                markerView.person = person
                break
            }
        }
        
        return markerView
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        tappedMarker = nil
        for line in curPolyLines {
            line.map = nil
        }
        curPolyLines.removeAll()
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        tappedMarker = marker
        DataManager.shared.drawPath(endLocation: NHLocation.init(latitude: marker.position.latitude, longitude: marker.position.longitude))
    }
    
//    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
//
//        tappedMarker = marker
//        DataManager.shared.drawPath(endLocation: NHLocation.init(latitude: marker.position.latitude, longitude: marker.position.longitude))
//        return true
//    }
}

//MARK: - Direction
extension MapsViewController: DataManagerDelegate {
    func dataManager(didUpdate location: NHLocation) {
        
    }
    
    func dataDidLoad() {
        
    }
    
    func dataManager(didGet routes: [[String: AnyObject]]) {
        curRoutes = routes
        for route in routes {
            
            guard let routeOverviewPolyline = route["overview_polyline"] as? [String: AnyObject] else {
                return
            }
            
            guard let points = routeOverviewPolyline["points"] as? String else {
                return
            }
            
            
            DispatchQueue.main.async {
                let path = GMSPath(fromEncodedPath: points)
                let polyline = GMSPolyline(path: path)
                
                polyline.strokeWidth = 5
                polyline.strokeColor = UIColor.red
                polyline.map = self.mapView
                
                self.curPolyLines.append(polyline)
            }
        }
    }

}
