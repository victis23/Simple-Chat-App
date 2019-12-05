//
//  AccessViewController.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/16/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit
import FacebookLogin
import AuthenticationServices
import FirebaseFirestore
import FirebaseAuth
import CryptoKit


/// Controller that handles access credentials and logging into Google Firebase.
class AccessViewController: UIViewController {
	
	// MARK: Class Properties | @IBOutlets --
	@IBOutlet weak var userNameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var regPasswordField: UITextField!
	@IBOutlet weak var backgroundImageView: UIImageView!
	@IBOutlet weak var iconImageView: UIImageView!
	@IBOutlet weak var viewTitle: UILabel!
	@IBOutlet weak var submitButton: UIButton!
	@IBOutlet weak var forgotUserNameButton: UIButton!
	@IBOutlet weak var forgotPasswordButton: UIButton!
	@IBOutlet weak var forgotCredentialsStack: UIStackView!
	@IBOutlet weak var loginWithAppleButtonStack: UIStackView!
	
	var generatedNonce : String!
	var fireBaseUserCreds : FireBaseUserCreds!
	var appleUserCreds : AppleUserCreds!
	var fbUserCreds : FacebookUserCreds!
	var loginCred : AuthCredentialToken!
	
	var appDelegate = UIApplication.shared.delegate as! AppDelegate
	
	//MARK: Publishers & Subscribers
	var isRegistration : Bool?
	
	//MARK: - State
	override func viewDidLoad() {
		super.viewDidLoad()
		setView()
		showLoginWithAppleButton()
		showLoginWithFacebookButton()
		checkFacebookLoginStatus()
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
		}else{
			regPasswordField.isHidden = true
			
			passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor : placeholderTextColor])
			
			viewTitle.text = "Login"
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
	
	/// Begins the authentication process.
	@IBAction func submitButtonTapped(_ sender: Any) {
		// Makes sure user has entered a correctly formated email address.
		guard let username = userNameTextField.text, username.contains("@") else {
			userNameTextField.text = nil
			passwordTextField.text = nil
			regPasswordField.text = nil
			userNameTextField.becomeFirstResponder()
			return
		}
		// Depending on whether the user is signing in or registering this switch control flow verifies entered values. If this is a registration matching emails are verified as well.
		switch isRegistration {
		case true:
			guard let password = passwordTextField.text, let passwordConfirmation = regPasswordField.text else {return}
			if password == passwordConfirmation {
				fireBaseUserCreds = FireBaseUserCreds(username: username, password: password)
				registrationAuthentification()
			}else{
				passwordTextField.text = nil
				regPasswordField.text = nil
				passwordTextField.becomeFirstResponder()
			}
		default:
			guard let password = passwordTextField.text else {return}
			fireBaseUserCreds = FireBaseUserCreds(username: username, password: password)
			loginAuthentification()
		}
	}
	
	///Controls which view is first responder.
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
	
	@IBAction func forgotUsernameButtonTapped(_ sender: Any) {
		print("Forgot Username")
	}
	
	@IBAction func forgotPasswordButtonTapped(_ sender: Any) {
		print("Forgot Password")
	}
	
	//MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == Keys.Segues.chatWindow {
			let navigationController = segue.destination as? UINavigationController
			let destinationController = navigationController?.topViewController as! ChatViewController
			
			let userCreds = sender as! AuthDataResult
			if userCreds.user.email == nil {
				destinationController.isFacebookSignIn = true
			}
			clearAllFields()
			view.endEditing(true)
		}
	}
}

//MARK: - FireBase Authorization Methods
extension AccessViewController {
	
	/// Creates credentials for new user on database.
	func registrationAuthentification(){
		Auth.auth().createUser(withEmail: fireBaseUserCreds.username, password: fireBaseUserCreds.password) { [weak self](result, error) in
			guard error == nil else {
				self?.showAlert(with: error)
				self?.forgotCredentialsStack.isHidden = false
				return
			}
			self?.performSegue(withIdentifier: Keys.Segues.chatWindow, sender: result)
		}
	}
	
	/// Allows existing users to sign-in to database.
	func loginAuthentification(){
		Auth.auth().signIn(withEmail: fireBaseUserCreds.username, password: fireBaseUserCreds.password) { [weak self](result, error) in
			guard error == nil else {
				self?.showAlert(with: error)
				self?.forgotCredentialsStack.isHidden = false
				return
			}
			guard let userInfo = result else {return}
			self?.performSegue(withIdentifier: Keys.Segues.chatWindow, sender: userInfo)
		}
	}
	
	/// Utilizes nonce and idToken provided by Sign-in with Apple to authenticate a user with Google Firebase.
	/// -	Important: Unlike the standard method for Firebase authentification, once the token is created here the user is good to go. Distringuishing between account creation and logging in is handled by `loginWithAppleClick(_:)`.
	func loginWithAppleIdAuthorization(){
		
		let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: appleUserCreds.idToken!, rawNonce: appleUserCreds.nonce)
		Auth.auth().signIn(with: credential) { [weak self](result, error) in
			
			if let error = error {
				print(error.localizedDescription)
				self?.showAlert(with: error)
				self?.forgotCredentialsStack.isHidden = false
			}
			guard let userInfo = result else {return}
			self?.performSegue(withIdentifier: Keys.Segues.chatWindow, sender: userInfo)
		}
	}
}

//MARK: - Login With Apple

extension AccessViewController : ASAuthorizationControllerDelegate {

	/// Creates the Sign-in With Apple Button and places it within the loginWithAppleButtonStack.
	func showLoginWithAppleButton(){
		let appleLoginButton = ASAuthorizationAppleIDButton()
		appleLoginButton.addTarget(self, action: #selector(loginWithAppleClicked(_:)), for: .touchUpInside)
		loginWithAppleButtonStack.addArrangedSubview(appleLoginButton)
	}
	
	/// Method that is called when user taps on button for Apple ID Sign-in.
	/// - Important:
	/// 	-	If user has already
	@objc func loginWithAppleClicked(_ sender: Any){
		
		let provider = ASAuthorizationAppleIDProvider()
		var request : ASAuthorizationAppleIDRequest!
		
		appleUserCreds = AppleUserCreds(nonce: AppleUserCreds.globalNonceCreator(), idToken: nil)
		
		var authorizationController : ASAuthorizationController?
		
		switch isRegistration {
		case false:
			let requests = [
				ASAuthorizationAppleIDProvider().createRequest(),
				ASAuthorizationPasswordProvider().createRequest(),
			]
			authorizationController = authorizationControllerMethod(requests: requests)
		default:
			request = provider.createRequest()
			request.requestedScopes = [.fullName, .email]
			request.nonce = appleUserCreds.sha256()
			authorizationController = authorizationControllerMethod(requests: [request])
		}
		
		let loginWithAppleAuthorizationController = authorizationController!
		loginWithAppleAuthorizationController.delegate = self
		loginWithAppleAuthorizationController.presentationContextProvider = self
		loginWithAppleAuthorizationController.performRequests()
	
	}
	
	/// Creates an `ASAuthorizationController` utilizing provided `ASAuthorizationRequest` Collections.
	func authorizationControllerMethod(requests : [ASAuthorizationRequest]) -> ASAuthorizationController {
		let controller = ASAuthorizationController(authorizationRequests: requests)
		return controller
	}
	
	func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		
		guard let appleIDCredentials = authorization.credential as? ASAuthorizationAppleIDCredential else {return}
		guard let appleIDToken = appleIDCredentials.identityToken else {return}
		
		appleUserCreds.authorizationCredential = authorization
		
		appleUserCreds.idToken = String(data: appleIDToken, encoding: .utf8)
		guard appleUserCreds.idToken != nil else {fatalError()}
		
		loginWithAppleIdAuthorization()

//		 How to save the values to the user device's keychain.
//		addToKeyChain()
	}
	
	func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
		print(error.localizedDescription)
	}
	
	func addToKeyChain(){
		guard let credential = appleUserCreds.authorizationCredential?.credential as? ASPasswordCredential else {return}
		let username = credential.user
		let password = credential.password
		
		guard let encodedPassword = password.data(using: String.Encoding.utf8) else {return}
		
		let newKeychainQuery : [String:Any] = [
			kSecClass as String:kSecClassKey,
			kSecAttrAccount as String:username,
			kSecValueRef as String:encodedPassword,
		]
		
		let status = SecItemAdd(newKeychainQuery as CFDictionary, nil)
		guard status == errSecSuccess else {fatalError()}
	}
}

extension AccessViewController : ASAuthorizationControllerPresentationContextProviding {
	func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
		
		return self.view.window!
		
	}
}

//MARK: - Facebook Login API
extension AccessViewController : LoginButtonDelegate {
	
	func checkFacebookLoginStatus(){
		guard let token = AccessToken.current else {
			print("No Token...")
			return
		}
		let facebookCredential = FacebookAuthProvider.credential(withAccessToken: token.tokenString)
		
		loginCred = AuthCredentialToken(authCredUniqueToken: facebookCredential)
		
		Auth.auth().signIn(with: loginCred.authCredUniqueToken) { (result, error) in
			if let error = error {
				print(error.localizedDescription)
			}
			guard let userInfo = result else {return}
			self.performSegue(withIdentifier: Keys.Segues.chatWindow, sender: userInfo)
		}
	}
	
	func showLoginWithFacebookButton(){
		
		let facebookLoginButton = FBLoginButton(permissions: [.publicProfile, .email,])
		facebookLoginButton.center = view.center
		facebookLoginButton.delegate = self
		loginWithAppleButtonStack.addArrangedSubview(facebookLoginButton)
	}
	
	func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
		guard let error = error else {
			guard let token = AccessToken.current?.tokenString else {return}
			fbUserCreds = FacebookUserCreds(accessToken: token)
			
			loginCred = AuthCredentialToken(authCredUniqueToken: FacebookAuthProvider.credential(withAccessToken: fbUserCreds.accessToken))
			
			Auth.auth().signIn(with: loginCred.authCredUniqueToken) { (result, error) in
				if let error = error {
					print(error.localizedDescription)
				}
				guard let userInfo = result else {return}
				self.performSegue(withIdentifier: Keys.Segues.chatWindow, sender: userInfo)
			}
			return
		}
		print(error.localizedDescription)
	}
	
	func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
		clearAllFields()
	}
}
