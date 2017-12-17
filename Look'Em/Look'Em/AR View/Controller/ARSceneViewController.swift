//
//  ARSceneViewController.swift
//  Look'Em
//
//  Created by Le Vu Hoai An on 12/16/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation
import GoogleMaps

class ARSceneViewController: UIViewController {
    
    var sceneView = SceneLocationView()
    
    var isLoaded: Bool = false
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataManager.shared.requestCurrentLocation()
    
        view.addSubview(sceneView)
        // Do any additional setup after loading the view.
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
         */
        
        UIApplication.shared.isIdleTimerDisabled = true
        sceneView.showsStatistics = true
        sceneView.automaticallyUpdatesLighting = true
        
        DataManager.shared.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.run()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.pause()
    }
    
    fileprivate func loadPeople() {
        for person in DataManager.shared.persons {
            var pinLocation: CLLocation
            let location2D = CLLocationCoordinate2D(latitude: person.location!.latitude, longitude: person.location!.longitude)
            pinLocation = CLLocation(coordinate: location2D, altitude: 0)
            
            let currentLocation = CLLocation(latitude: DataManager.shared.myLocation.latitude, longitude: DataManager.shared.myLocation.longitude)
            
            let distance = currentLocation.distance(from: pinLocation)
            if distance > 20.0 {
                let aView = PersonARView(frame: CGRect(x: 0, y: 0, width: 150, height: 200))
                aView.person = person
                aView.delegate = self
                let pinLocationNode = LocationAnnotationNode(location: pinLocation, view: aView)
                sceneView.addLocationNodeWithConfirmedLocation(locationNode: pinLocationNode)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = view.safeAreaLayoutGuide.layoutFrame
    }
    
//    @objc func tapped(recognizer :UITapGestureRecognizer) {
//        let sceneView = recognizer.view as! ARSCNView
//        let touchLocation = recognizer.location(in: sceneView)
//        let hitResults = sceneView.hitTest(touchLocation, options: [:])
//        if !hitResults.isEmpty {
//            guard let hitResult = hitResults.first else {
//                return
//            }
//            print("HITTTT")
//        }
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension ARSceneViewController: DataManagerDelegate {
    func dataManager(didGet routes: [[String : AnyObject]]) {
        
        sceneView.pause()
        DispatchQueue.main.sync {
            let vc = ARFindRoutesViewController()
            vc.routes = routes
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func dataManager(didUpdate location: NHLocation) {

    }
    
    func dataDidLoad() {
        loadPeople()
    }
}

extension ARSceneViewController: PersonARViewDelegate {
    func didTapFindButton(to latitude: Double, longtitude: Double) {
        let endPoint = NHLocation(latitude: latitude, longitude: longtitude)
        DataManager.shared.drawPath(endLocation: endPoint)
    }
}
