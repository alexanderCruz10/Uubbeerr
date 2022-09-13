//
//  Service.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-13.
//

import Firebase

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")

struct Service{
    
    static let shared = Service()
    let currentuid = Auth.auth().currentUser?.uid
    
    func fetchData(completion: @escaping (User) -> Void) {
        REF_USERS.child(currentuid!).observe(.value) { snapshot in
            guard let dictionary = snapshot.value as? [String:Any] else { return }
           
            let user = User(dictionary: dictionary)
            
            print("DEBUG: User email is: \(user.email)")
            print("DEBUG: User email is: \(user.fullName)")
            
            completion(user)
        }
    }
}
