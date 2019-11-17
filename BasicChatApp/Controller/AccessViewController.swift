//
//  AccessViewController.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/16/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit
import AuthenticationServices
import FirebaseFirestore
import FirebaseAuth

class AccessViewController: UIViewController, ASAuthorizationControllerDelegate {
	
	
	@IBOutlet weak var userNameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var regPasswordField: UITextField!
	@IBOutlet weak var backgroundImageView: UIImageView!
	@IBOutlet weak var iconImageView: UIImageView!
	@IBOutlet weak var viewTitle: UILabel!
	@IBOutlet weak var loginWithAppleButton: UIButton!
	@IBOutlet weak var submitButton: UIButton!
	@IBOutlet weak var forgotUserNameButton: UIButton!
	@IBOutlet weak var forgotPasswordButton: UIButton!
	@IBOutlet weak var forgotCredentialsStack: UIStackView!
	
	
	var isRegistration : Bool?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setView()
		
	}
	
	// MARK: Class Methods
	
	/// Method called during segue from `ViewController`.
	/// - Note: The boolean is actually determined by the tag assigned to the button which calls the segue.
	/// - Important: This method is called prior to `viewDidLoad`.
	func checkIfIsRegistration(is bool: Bool){
		isRegistration = bool
	}
	
	/// Method uses control flow logic to determine what views to present to the user.
	func setView(){
		guard let isRegistrationView = isRegistration else {return}
		backgroundImageView.image = UIImage(named: Keys.Images.viewMainBackgroundImage)
		iconImageView.image = UIImage(named: Keys.Images.applogo)
		backgroundImageView.contentMode = .scaleAspectFill
		iconImageView.contentMode = .scaleAspectFit
		submitButton.layer.cornerRadius = 5
		forgotCredentialsStack.isHidden = true
		forgotUserNameButton.setTitle("Get Username Reminder", for: .normal)
		forgotPasswordButton.setTitle("Reset Password", for: .normal)
		
		// Creates color being used in control logic for placeholder text.
		let placeholderTextColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
		
		userNameTextField.attributedPlaceholder = NSAttributedString(string: "E-mail", attributes: [NSAttributedString.Key.foregroundColor : placeholderTextColor])
		
		// Logic that determines what state the view is currently in.
		if isRegistrationView {
			
			regPasswordField.textContentType = .newPassword
			passwordTextField.textContentType = .newPassword
			
			regPasswordField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor : placeholderTextColor])
			
			passwordTextField.attributedPlaceholder = NSAttributedString(string: "Confirm Password", attributes: [NSAttributedString.Key.foregroundColor : placeholderTextColor])
			
			viewTitle.text = "Registration"
			loginWithAppleButton.setTitle("Register using Apple ID", for: .normal)
		}else{
			regPasswordField.isHidden = true
			
			passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor : placeholderTextColor])
			
			viewTitle.text = "Login"
			loginWithAppleButton.setTitle("Login with Apple", for: .normal)
			passwordTextField.isSecureTextEntry = true
		}
	}
	
	/// Displays error message on screen showing user why they have not been able to login.
	/// - Note: Gets called during Google Firebase Authentification if user has an error when registering or logging in.
	func showAlert(with error: Error?){
		guard let error = error else {return}
		let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
		let accept = UIAlertAction(title: "Got It!", style: .cancel, handler: nil)
		alert.addAction(accept)
		present(alert, animated: true) { [weak self] in
			self?.clearAllFields()
		}
		view.endEditing(true)
	}
	
	func clearAllFields(){
		userNameTextField.text = nil
		passwordTextField.text = nil
		regPasswordField.text = nil
	}
	
	
	
	//MARK: - IBActions
	
	@IBAction func submitButtonTapped(_ sender: Any) {
		guard let username = userNameTextField.text, username.contains("@") else {
			userNameTextField.text = nil
			passwordTextField.text = nil
			regPasswordField.text = nil
			userNameTextField.becomeFirstResponder()
			return
		}
		
		switch isRegistration {
		case true:
			guard let password = passwordTextField.text, let passwordConfirmation = regPasswordField.text else {return}
			if password == passwordConfirmation {
				registrationAuthentification(username: username, password: password)
			}else{
				passwordTextField.text = nil
				regPasswordField.text = nil
				passwordTextField.becomeFirstResponder()
			}
		default:
			guard let password = passwordTextField.text else {return}
			loginAuthentification(username: username, password: password)
		}
	}
	
	@IBAction func returnKeyPressed(_ sender: UITextField) {
		switch sender {
		case userNameTextField:
			if isRegistration! {
				regPasswordField.becomeFirstResponder()
			}else{
				passwordTextField.becomeFirstResponder()
			}
		case regPasswordField:
			passwordTextField.becomeFirstResponder()
		case passwordTextField:
			submitButtonTapped(sender)
		default:
			break
		}
	}
	
	
	@IBAction func loginWithAppleButtonClicked(_ sender: Any) {
		
		let provider = ASAuthorizationAppleIDProvider()
		let request = provider.createRequest()
		let controller = ASAuthorizationController(authorizationRequests: [request])
		controller.delegate = self
	}
	
	//MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == Keys.Segues.chatWindow {
			let navigationController = segue.destination as? UINavigationController
			let destinationController = navigationController?.topViewController as! ChatViewController
			destinationController.user = sender as? AuthDataResult
			clearAllFields()
			view.endEditing(true)
		}
	}
}

//MARK: - FireBase Authorization Methods
extension AccessViewController {
	
	func registrationAuthentification(username: String, password: String){
		Auth.auth().createUser(withEmail: username, password: password) { [weak self](result, error) in
			guard error == nil else {
				self?.showAlert(with: error)
				self?.forgotCredentialsStack.isHidden = false
				return
			}
			self?.performSegue(withIdentifier: Keys.Segues.chatWindow, sender: result)
		}
	}
	
	func loginAuthentification(username: String, password: String){
		Auth.auth().signIn(withEmail: username, password: password) { [weak self](result, error) in
			guard error == nil else {
				self?.showAlert(with: error)
				self?.forgotCredentialsStack.isHidden = false
				return
			}
			guard let userInfo = result else {return}
			self?.performSegue(withIdentifier: Keys.Segues.chatWindow, sender: userInfo)
		}
	}
	
	
}
