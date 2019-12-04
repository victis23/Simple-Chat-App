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
	
	/// Allows existing users to sign-in to database.
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
	
	/// Utilizes nonce and idToken provided by Sign-in with Apple to authenticate a user with Google Firebase.
	/// -	Important: Unlike the standard method for Firebase authentification, once the token is created here the user is good to go. Distringuishing between account creation and logging in is handled by `loginWithAppleClick(_:)`.
	func loginWithAppleIdAuthorization(idToken:String, nonce: String){
		
		let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idToken, rawNonce: nonce)
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
		generatedNonce = globalNonceCreator()
		
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
			request.nonce = sha256(generatedNonce)
			authorizationController = authorizationControllerMethod(requests: [request])
		}
		
		let loginWithAppleAuthorizationController = authorizationController!
		loginWithAppleAuthorizationController.delegate = self
		loginWithAppleAuthorizationController.presentationContextProvider = self
		loginWithAppleAuthorizationController.performRequests()
	
	}
	
	/// Encripts generated nonce which is assigned to the `request.nonce` property held by device For this App's Bundle.
	func sha256(_ input: String)->String{
		let inputData = Data(input.utf8)
		let hashData = SHA256.hash(data: inputData)
		let hashString = hashData.compactMap({
			return String(format: "%02x", $0)
			}).joined()
		return hashString
	}
	
	/// Creates an `ASAuthorizationController` utilizing provided `ASAuthorizationRequest` Collections.
	func authorizationControllerMethod(requests : [ASAuthorizationRequest]) -> ASAuthorizationController {
		let controller = ASAuthorizationController(authorizationRequests: requests)
		return controller
	}
	
	/// Creates a randomized string to be used as unique nonce value.
	func globalNonceCreator(length:Int = 32)->String{
		
		precondition(length > 0)
		
		let availableCharacters : Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
		
		var result = ""
		var remainingLength = length
		
		while remainingLength > 0 {
			let randoms: [UInt8] = (0..<16).map({_ in
				var random: UInt8 = 0
				let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
				
				if errorCode != errSecSuccess {
					fatalError("Unable to create global nonce: \(errorCode)")
				}
				return random
			})
			
			randoms.forEach({ random in
				
				if length == 0 {
					return
				}
				
				if random < availableCharacters.count {
					result.append(availableCharacters[Int(random)])
					remainingLength -= 1
				}
			})
		}
		
		return result
	}
	
	func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		
		guard let appleIDCredentials = authorization.credential as? ASAuthorizationAppleIDCredential else {return}
		guard let appleIDToken = appleIDCredentials.identityToken else {return}
		guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {return}
	
		loginWithAppleIdAuthorization(idToken: idTokenString, nonce: generatedNonce)

		// How to save the values to the user device's keychain.
		addToKeyChain()
	}
	
	func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
		print(error.localizedDescription)
	}
	
	func addToKeyChain(){
		
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
		Auth.auth().signIn(with: facebookCredential) { (result, error) in
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
			let facebookCreds = FacebookAuthProvider.credential(withAccessToken: token)
			Auth.auth().signIn(with: facebookCreds) { (result, error) in
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
