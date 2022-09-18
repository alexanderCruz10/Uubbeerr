//
//  PickUpController.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-17.
//

import UIKit
import MapKit

protocol PickUpControllerDelegate{
    func didAcceptTrip(_ trip: Trip)
}

class PickUpController: UIViewController{
   
    //MARK: - Properties
    private let mapView = MKMapView()
    let trip: Trip
    
    var delegate: PickUpControllerDelegate?
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(imageLiteralResourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDismissal), for: .touchUpInside)
        return button
    }()
    
    private let pickUpLabel: UILabel = {
        let label = UILabel()
        label.text = "Would you like to pickup this passenger"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private let acceptTripButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleAcceptTrip), for: .touchUpInside)
        button.backgroundColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("ACCEPT TRIP", for: .normal)
        return button
    }()
    
    
    
    init(trip: Trip){
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - LifeCylce
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("DEBUG: Trip passenger pick up coordinates is: \(trip.pickupCoordinates)")
        
        configureUI()
        configureMapView()
    }
    
    //MARK: - Selectors
    @objc func handleDismissal(){
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleAcceptTrip(){
        Service.shared.acceptTrip(trip: trip) { error, ref in
            self.delegate?.didAcceptTrip(self.trip)
        }
    }
    
    //MARK: - Database
    
    
    //MARK: - Functions
    func configureUI(){
        
        view.backgroundColor = .backgroundColor
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingLeft: 16)
        
        view.addSubview(mapView)
        mapView.setDimensions(height: 270, width: 270)
        mapView.layer.cornerRadius = 270 / 2
        mapView.centerX(inView: view)
        mapView.centerY(inView: view, constant: -200)
        
        view.addSubview(pickUpLabel)
        pickUpLabel.centerX(inView: view)
        pickUpLabel.anchor(top: mapView.bottomAnchor, paddingTop: 16)
        
        view.addSubview(acceptTripButton)
        acceptTripButton.anchor(top:pickUpLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,
                                paddingTop: 16, paddingLeft: 32, paddingRight: 32, height: 50)
    }
    
    func configureMapView(){
       let region = MKCoordinateRegion(center: trip.pickupCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: false)
        
        mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
    }
}
