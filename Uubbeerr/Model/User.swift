//
//  User.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-13.
//

struct User{
    
    let fullName: String
    let email: String
    let accountType: Int
    
    init(dictionary: [String:Any]){
        self.fullName = dictionary["fullname"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.accountType = dictionary["accountType"] as? Int ?? 0
    }
}
