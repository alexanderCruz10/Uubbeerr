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
    
    private let inputActivationView = LocationInpurActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private let locationInputViewHeight : CGFloat = 200
    private var searchResults = [MKPlacemark]()
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
    private var user:User?{
        didSet{
            locationInputView.user = user
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
            }
        }
    }
    
    //MARK: - Database
    
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
    
    //MARK: - Functions
    
    func configure(){
        configureUI()
        fetchUserData()
        fetchDrviers()
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
        
       view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,paddingTop: 16,
                            paddingLeft: 20, width: 30, height: 30)
        
       view.addSubview(inputActivationView)
       inputActivationView.centerX(inView: view)
       inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top:actionButton.bottomAnchor, paddingTop: 32)
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
    
    func dismissLocationView(completion: ((Bool) -> Void)? = nil){
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
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
       // self.tableView.backgroundColor = .lightGray
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
            self.mapView.showAnnotations(annotations, animated: true)
        }
    }
}
