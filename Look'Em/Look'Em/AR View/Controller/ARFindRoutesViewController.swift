//
//  ARFindRoutesViewController.swift
//  Look'Em
//
//  Created by Le Vu Hoai An on 12/17/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import CoreLocation

class ARFindRoutesViewController: UIViewController {
    
    var routes = [[String : AnyObject]]()

    var sceneView = SceneLocationView()
    var closeButton: UIButton = {
        var button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        button.setTitle("Close", for: UIControlState.normal)
        button.addTarget(self, action: #selector(dissmissView), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        sceneView.run()
        view.addSubview(sceneView)
        view.addSubview(closeButton)
        
        DataManager.shared.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        for route in routes {
            
            guard let legs = route["legs"] as? [[String: AnyObject]] else {
                return
            }
            var i = 0
            for leg in legs {
                
                guard let steps = leg["steps"] as? [[String: AnyObject]] else { return }
                
                for step in steps {
                    guard let start = step["start_location"] as? [String: AnyObject] else {return}
                    guard let end = step["end_location"] as? [String: AnyObject] else {return}
                    
                    guard let sLat = start["lat"] as? Double else { return }
                    
                    guard let sLong = start["lng"] as? Double else { return }
                    
                    guard let eLat = end["lat"] as? Double else { return }
                    
                    guard let eLong = end["lng"] as? Double else { return }
                    
                    let startLocation = NHLocation(latitude: sLat, longitude: sLong)
                    let endLocation = NHLocation(latitude: eLat, longitude: eLong)
                    
                    let pinLocationNode1 = LocationAnnotationNode(location: CLLocation.init(coordinate: startLocation.cllocation2D(), altitude: 0) , width: 150, height: 200, texture: #imageLiteral(resourceName: "Start"))
                    sceneView.addLocationNodeWithConfirmedLocation(locationNode: pinLocationNode1)
                    
                    let pinLocationNode2 = LocationAnnotationNode(location: CLLocation.init(coordinate: endLocation.cllocation2D(), altitude: 0), width: 150, height: 200, texture: #imageLiteral(resourceName: "End"))
                    sceneView.addLocationNodeWithConfirmedLocation(locationNode: pinLocationNode2)
                }
                
            }
            
//            guard let start = ((((route["legs"] as! [[String: AnyObject]])[i] ))["start_location"])  as? [String: AnyObject] else { return }
//
//            guard let end = ((((route["legs"] as! [[String: AnyObject]])[i] ))["end_location"]) as? [String: AnyObject] else { return }
//
//            guard let sLat = start["lat"] as? Double else { return }
//
//            guard let sLong = start["lng"] as? Double else { return }
//
//            guard let eLat = end["lat"] as? Double else { return }
//
//            guard let eLong = end["lng"] as? Double else { return }
            
            
//            let startLocation = NHLocation(latitude: sLat, longitude: sLong)
//            let endLocation = NHLocation(latitude: eLat, longitude: eLong)
//            
//            let pinLocationNode1 = LocationAnnotationNode(location: CLLocation.init(coordinate: startLocation.cllocation2D(), altitude: 0) , width: 150, height: 200, texture: #imageLiteral(resourceName: "Start"))
//            sceneView.addLocationNodeWithConfirmedLocation(locationNode: pinLocationNode1)
//            
//            let pinLocationNode2 = LocationAnnotationNode(location: CLLocation.init(coordinate: endLocation.cllocation2D(), altitude: 0), width: 150, height: 200, texture: #imageLiteral(resourceName: "End"))
//            sceneView.addLocationNodeWithConfirmedLocation(locationNode: pinLocationNode2)
//            
//            i += 1
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func dissmissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.pause()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ARFindRoutesViewController : DataManagerDelegate {
    func dataManager(didUpdate location: NHLocation) {
        
    }
    
    func dataDidLoad() {
        
    }
    
    func dataManager(didGet routes: [[String : AnyObject]]) {
        
    }
    
    
}
