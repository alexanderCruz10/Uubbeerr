//
//  LocationInputView.swift
//  Uubbeerr
//
//  Created by Alex Cruz on 2022-09-12.
//

import UIKit

protocol LocationInputViewDelegate{
    func dismissLocationInputView()
}

class LocationInputView: UIView{
    
    // MARK: - Properties
    
    var delegate: LocationInputViewDelegate?
    
    private let backButton: UIButton = {
         let button = UIButton(type: .system)
         button.setImage(UIImage(imageLiteralResourceName: "baseline_arrow_back_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
         button.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)
         return button
     }()
     
    private let titleLabel: UILabel = {
         let label = UILabel()
         label.text = "Alex Cruz"
         label.font = UIFont.systemFont(ofSize: 16)
         label.textColor = .darkGray
         return label
     }()
     
    private let startLocationIndicatorView: UIView = {
         let view = UIView()
         view.backgroundColor = .lightGray
         return view
     }()
     
    private let linkingView: UIView = {
         let view = UIView()
         view.backgroundColor = .darkGray
         return view
     }()
     
    private let destinationIndicatorView: UIView = {
         let view = UIView()
         view.backgroundColor = .black
         return view
     }()
     
    private lazy var startLocationTextField:UITextField = {
         let tf = UITextField()
         
         tf.placeholder = "Current Location"
         tf.backgroundColor = .groupTableViewBackground
         tf.isEnabled = false
         tf.font = UIFont.systemFont(ofSize: 14)
         
         let paddingView = UIView()
         paddingView.setDimensions(height: 30, width: 8)
         tf.leftView = paddingView
         tf.leftViewMode  = .always
         
         return tf
     }()
     
    private lazy var destinationLocationTextField:UITextField = {
         let tf = UITextField()
         tf.placeholder = "Enter a destination..."
         tf.backgroundColor = .lightGray
         tf.returnKeyType = .search
         tf.font = UIFont.systemFont(ofSize: 14)
         
         let paddingView = UIView()
         paddingView.setDimensions(height: 30, width: 8)
         tf.leftView = paddingView
         tf.leftViewMode  = .always
         
         return tf
     }()
     
     
     // MARK: - LifeCycle
    
    override init(frame: CGRect) {
         super.init(frame: frame)
         
         addShadow()
         
         backgroundColor = .white
        
         addSubview(backButton)
         backButton.anchor(top: topAnchor, left: leftAnchor,paddingTop: 44,
                           paddingLeft: 12, width: 24, height: 25)
         
         addSubview(titleLabel)
         titleLabel.centerY(inView: backButton)
         titleLabel.centerX(inView: self)
         
         addSubview(startLocationTextField)
         startLocationTextField.anchor(top:backButton.bottomAnchor, left: leftAnchor, right: rightAnchor,
                                       paddingTop: 4, paddingLeft: 40,paddingRight: 40,  height: 30)
         
         addSubview(destinationLocationTextField)
         destinationLocationTextField.anchor(top:startLocationTextField.bottomAnchor, left: leftAnchor, right: rightAnchor,
                                       paddingTop: 12, paddingLeft: 40,paddingRight: 40, height: 30)
         
         addSubview(startLocationIndicatorView)
         startLocationIndicatorView.centerY(inView: startLocationTextField, leftAnchor: leftAnchor, paddingLeft: 20)
         startLocationIndicatorView.setDimensions(height: 6, width: 6)
         startLocationIndicatorView.layer.cornerRadius = 6 / 2
         
         addSubview(destinationIndicatorView)
         destinationIndicatorView.centerY(inView: destinationLocationTextField, leftAnchor: leftAnchor, paddingLeft: 20)
         destinationIndicatorView.setDimensions(height: 6, width: 6)
         
         addSubview(linkingView)
         linkingView.anchor(top: startLocationIndicatorView.bottomAnchor, bottom: destinationIndicatorView.topAnchor, paddingTop: 4, paddingBottom: 4, width: 0.5)
         linkingView.centerX(inView: startLocationIndicatorView)
     }
     
     required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
     
     @objc func handleBackTapped() {
         print("DEBUG: back button pressed")
         delegate?.dismissLocationInputView()
     }
}
