//
//  HomeController.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-12.
//

import UIKit
import Firebase
import MapKit

private let resuseIdentifer = "LocationCell"
private let annotationIdentifer = "DriverAnno"

class HomeController: UIViewController{
    
    // MARK: - Properties
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    
    private let inputActivationView = LocationInpurActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private let locationInputViewHeight : CGFloat = 200
    private var user:User?{
        didSet{
            locationInputView.user = user
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
        enableLocationService()
        fetchUserData()
        fetchDrviers()
        //signOut()
    }
    
    func fetchUserData(){
        
        guard let currentuid = Auth.auth().currentUser?.uid else {return}
        Service.shared.fetchUserData(currentUid: currentuid) { user in
            self.user = user
        }
    }
    
    func fetchDrviers(){
        
        guard let location = locationManager?.location else {return }
        Service.shared.fetchDrivers(location: location) { driver in
            guard let coordinate = driver.location?.coordinate else{ return}
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            
            var driverIsVisble: Bool{
                return self.mapView.annotations.contains { annotation in
                    guard let driveranno = annotation as? DriverAnnotation else{
                        return false
                    }
                    
                    if driveranno.uid == driver.uid{
                        driveranno.updateAnnotationUpdate(withCoordinate: coordinate)
                        return true
                    }
                    return false
                }
            }
            
            if !driverIsVisble{
                self.mapView.addAnnotation(annotation)
            }
        }
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
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
    
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }catch{
            print("Debug: Error sign out")
        }
    }
    
    
    func configureUI(){
       configureMapView()
        
       view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top:view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }
        
        configureTableView()
    }
    func configureMapView(){
        
        view.addSubview(mapView)
        mapView.frame = view.frame
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    func configureLocationInputView(){
        
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor,
                                 right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0
        
        UIView.animate(withDuration: 0.5) {
            self.locationInputView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }
    
    func configureTableView(){
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: resuseIdentifer)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()

        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        view.addSubview(tableView)
    }
}

extension HomeController: CLLocationManagerDelegate{
    
    func enableLocationService(){
        
        switch CLLocationManager.authorizationStatus(){
        case .notDetermined:
            print("DEBUG: Not Determined")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Auth always")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: When in use")
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
}

extension HomeController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? DriverAnnotation{
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifer)
            view.image = UIImage(imageLiteralResourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
}
extension HomeController: LocationInputActivationViewDelegate{
    
    func presentLocationInputView() {
        
       inputActivationView.alpha = 0
       configureLocationInputView()
    }
}

extension HomeController: LocationInputViewDelegate{
    
    func dismissLocationInputView() {
        
       UIView.animate(withDuration: 0.3) {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
        } completion: { _ in
            self.locationInputView.removeFromSuperview()
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
            }
        }
    }
}

extension HomeController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       // self.tableView.backgroundColor = .lightGray
        return "Test"
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2:5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: resuseIdentifer, for: indexPath) as!
        LocationCell
        
        return cell
    }
}
