//
//  HomeController.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-12.
//

import UIKit
import Firebase
import MapKit
import Foundation

private let resuseIdentifer = "LocationCell"
private let annotationIdentifer = "DriverAnno"

private enum ActionButtonConfiguration{
    case showMenu
    case dismissActionMenu
    
    init(){
        self = .showMenu
    }
}

class HomeController: UIViewController{
    
    // MARK: - Properties
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let rideActionView = RideActionView()
    private let inputActivationView = LocationInpurActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private let locationInputViewHeight : CGFloat = 200
    private let rideActionViewHeight : CGFloat = 300
    private var searchResults = [MKPlacemark]()
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
  
    
    private var user:User?{
        didSet{
            locationInputView.user = user
            if user?.accountType == .passenger {
                fetchDrviers()
                configureLocationInputActivationView()
                observeCurrentTrip()
            }else{
                observeTrips()
                
            }
        }
    }
    
    private var trip: Trip?{
        didSet{
            guard let trip = trip else {
                return
            }
            guard let user = user else {
                return
            }
            
            if user.accountType == .driver{
                let controller = PickUpController(trip: trip)
                controller.modalPresentationStyle = .fullScreen
                controller.delegate = self
                self.present(controller, animated: true, completion: nil)
            }else{
                print("DEBUG: show ride action view for accepted trip")
                
            }
        }
    }
    
    private let actionButton:UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(imageLiteralResourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
        enableLocationService()
        
        //signOut()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let trip = trip else {
            return
        }
    }
    //MARK: - Seleectors
    
    @objc func actionButtonPressed(){
        switch actionButtonConfig {
        case .showMenu:
            print("DEBUG: Handle Show Menu")
        case .dismissActionMenu:
            removeAnnotationsAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
        }
    }
    
    //MARK: - Database
    func observeCurrentTrip(){
        
        Service.shared.observeCurrentTrip { trip in
            self.trip = trip
            if trip.state == .accepted{
                self.shouldPresentLoadingView(false)
                
                guard let driverUid = trip.driverUid else {return}
                
                Service.shared.fetchUserData(currentUid: driverUid) { driver in
                    self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
                
            }
        }
       
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
           configure()
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
    
    func observeTrips(){
        
        Service.shared.observeTrip { trip in
            self.trip = trip
        }
    }
    //MARK: - Functions
    
    func configure(){
        configureUI()
        fetchUserData()
    }
    
    fileprivate func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dismissActionMenu:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionMenu
        }
    }
    
    func configureUI(){
        
       configureMapView()
       configureRideActionView()
        
       view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,paddingTop: 16,
                            paddingLeft: 20, width: 30, height: 30)
        
        configureTableView()
    }
    
    func configureLocationInputActivationView(){
        
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
         inputActivationView.anchor(top:actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
         }
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
    
    func configureRideActionView(){
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }
    
    func dismissLocationView(completion: ((Bool) -> Void)? = nil){
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
    }
    
    func animateRideActionView(shouldShow: Bool, destintation: MKPlacemark? = nil,
                               config: RideActionViewConfiguration? = nil, user: User? = nil){
        
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        
        if shouldShow{
            guard let config = config else {
                return
            }
            
            if let destintation = destintation {
                self.rideActionView.destination = destintation
            }
            
            if let user = user {
                rideActionView.user = user
            }
            
            rideActionView.configureUI(withConfig: config)
        }
    }
}

private extension HomeController{
    
    func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void){
        
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {return}
            response.mapItems.forEach { item in
                results.append(item.placemark)
            }
            completion(results)
        }
    }
    
    func generatePolyLine(toDestination destination: MKMapItem){
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { response, error in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        
       if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    func centerMapOnUserLocation(){
        guard let coordinate = locationManager?.location?.coordinate else { return}
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
}
extension HomeController: LocationInputActivationViewDelegate{
    
    func presentLocationInputView() {
       inputActivationView.alpha = 0
       configureLocationInputView()
    }
}

extension HomeController: LocationInputViewDelegate{
   
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { results in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.5) {
               self.inputActivationView.alpha = 1
           }
        }
    }
}

extension HomeController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Test"
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2:searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: resuseIdentifer, for: indexPath) as!
        LocationCell
        
        if indexPath.section == 1{
            cell.placeMark = searchResults[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedPlaceMark = searchResults[indexPath.row]
    
        
        configureActionButton(config: .dismissActionMenu)
        
        let destination = MKMapItem(placemark: selectedPlaceMark)
        generatePolyLine(toDestination: destination)
        
        dismissLocationView { _  in
           let annotation = MKPointAnnotation()
           annotation.coordinate = selectedPlaceMark.coordinate
           self.mapView.addAnnotation(annotation)
           self.mapView.selectAnnotation(annotation, animated: true)
            
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self) })
            self.mapView.zoomToFit(annotations: annotations)
            self.animateRideActionView(shouldShow: true, destintation: selectedPlaceMark, config: .requestRide)
        }
    }
}

extension HomeController: RideActionViewDelegate{
    func uploadTrip(_ view: RideActionView) {
        guard let pickUpCoordinates = locationManager?.location?.coordinate else { return}
        guard let destinationCoordinate = view.destination?.coordinate else {return}
        
        shouldPresentLoadingView(true, message: "Finding you a ride")
        Service.shared.uploadTrip(pickUpCoordinates, destinationCoordinate) { (err, ref) in
            if let error = err {
                print("DEBUG: Failed to upload trip with error \(error)")
                return
            }
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
        }
    }
    
    func cancelTrip() {
        Service.shared.cancelTrip { error, ref in
            if let error = error {
                print("DEBUG: Error deleting trip")
            }
            self.animateRideActionView(shouldShow: false)
            self.shouldPresentLoadingView(false)
            self.removeAnnotationsAndOverlays()
            
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
            }
        }
    }
}

extension HomeController: PickUpControllerDelegate{
    
    func didAcceptTrip(_ trip: Trip) {
        
        let anno = MKPointAnnotation()
        anno.coordinate = trip.pickupCoordinates
        mapView.addAnnotation(anno)
        
        let placeMark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placeMark)
        generatePolyLine(toDestination: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
        
        Service.shared.observeTripCancelled(trip: trip) {
            self.removeAnnotationsAndOverlays()
            self.animateRideActionView(shouldShow: false)
            self.centerMapOnUserLocation()
            self.presentAlertController(withTitle: "Sorry!", message: "The passenger has cancelled the ride. Press OK to Continue")
        }
        
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(currentUid: trip.passengerUid) { passenger in
                self.animateRideActionView(shouldShow: true,config: .tripAccepted, user: passenger)
            }
        }
    }
    
    
}
