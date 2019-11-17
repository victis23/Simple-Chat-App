//
//  AccessViewController.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/16/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit
import AuthenticationServices

class AccessViewController: UIViewController, ASAuthorizationControllerDelegate {
	

	@IBOutlet weak var userNameTextField: UITextField!
	
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var regPasswordField: UITextField!
	@IBOutlet weak var backgroundImageView: UIImageView!
	@IBOutlet weak var iconImageView: UIImageView!
	@IBOutlet weak var viewTitle: UILabel!
	@IBOutlet weak var loginWithAppleButton: UIButton!
	
	var isRegistration : Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
		setView()
		
    }
	
	func checkIfIsRegistration(is bool: Bool){
		isRegistration = bool
	}
	
	func setView(){
		guard let isRegistrationView = isRegistration else {return}
		userNameTextField.placeholder = "Username"
		backgroundImageView.image = UIImage(named: Keys.Images.viewMainBackgroundImage)
		iconImageView.image = UIImage(named: Keys.Images.applogo)
		backgroundImageView.contentMode = .scaleAspectFill
		iconImageView.contentMode = .scaleAspectFit
		
		if isRegistrationView {
			regPasswordField.placeholder = "Password"
			passwordTextField.placeholder = "Confirm Password"
			viewTitle.text = "Registration"
			loginWithAppleButton.setTitle("Register using Apple Id", for: .normal)
		}else{
			regPasswordField.isHidden = true
			passwordTextField.placeholder = "Password"
			viewTitle.text = "Login"
			loginWithAppleButton.setTitle("Login with Apple", for: .normal)
			passwordTextField.isSecureTextEntry = true
		}
	}
	
	
	@IBAction func loginWithAppleButtonClicked(_ sender: Any) {
		
		let provider = ASAuthorizationAppleIDProvider()
		let request = provider.createRequest()
		let controller = ASAuthorizationController(authorizationRequests: [request])
		controller.delegate = self
	}
}
