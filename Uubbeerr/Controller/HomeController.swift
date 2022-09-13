//
//  HomeController.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-12.
//

import UIKit
import Firebase
import MapKit
import CoreLocation

class HomeController: UIViewController{
    
    // MARK: - Properties
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
        enableLocationService()
        //signOut()
    }
    
    func checkIfUserIsLoggedIn(){
        
        if Auth.auth().currentUser?.uid == nil{
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
    
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }else{
           configureUI()
        }
    }
    
    func signOut(){
        do{
            try Auth.auth().signOut()
        }catch{
            print("Debug: Error sign out")
        }
    }
    
    
    func configureUI(){
       configureMapView()
    }
    func configureMapView(){
        
        view.addSubview(mapView)
        mapView.frame = view.frame
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
}

extension HomeController: CLLocationManagerDelegate{
    
    func enableLocationService(){
        
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus(){
        case .notDetermined:
            print("DEBUG: Not Determined")
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Auth always")
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: When in use")
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse{
            locationManager.requestAlwaysAuthorization()
        }
    }
}

