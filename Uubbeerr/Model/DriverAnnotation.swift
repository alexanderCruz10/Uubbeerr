//
//  DriverAnnotation.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-13.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation{
    
    dynamic var coordinate: CLLocationCoordinate2D
    var uid: String
    
    init(uid: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
    func updateAnnotationUpdate(withCoordinate coordinate: CLLocationCoordinate2D){
        UIView.animate(withDuration: 0.2) {
            self.coordinate = coordinate
        }
    }
}
