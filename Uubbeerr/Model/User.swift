//
//  User.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-13.
//

import CoreLocation

struct User{
    
    let fullName: String
    let email: String
    let accountType: Int
    var location: CLLocation?
    let uid: String
    
    init(uid: String, dictionary: [String:Any]){
        self.uid = uid
        self.fullName = dictionary["fullname"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.accountType = dictionary["accountType"] as? Int ?? 0
    }
}
