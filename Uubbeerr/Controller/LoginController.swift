//
//  LoginController.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-10.
//

import UIKit

class LoginController: UIViewController{
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    }
}
