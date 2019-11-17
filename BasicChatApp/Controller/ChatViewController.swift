//
//  ChatViewController.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/17/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController {
	
	
	
	enum Sections {
		case main
	}
	
	//MARK: - View Controller Property List Begins | IBOutlets & Class Properties
	
	@IBOutlet weak var communicationStack: UIStackView!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var backgroundImage: UIImageView!
	@IBOutlet weak var sendButton: UIButton!
	@IBOutlet weak var messageField: UITextView!
	var dataSource : UITableViewDiffableDataSource<Sections,Chats>!
	// Holds data about user currently signed in.
	var user : AuthDataResult?
	// Names used to identify Keyboard events.
	var show : NSNotification.Name = UIResponder.keyboardDidShowNotification
	var hide : NSNotification.Name = UIResponder.keyboardDidHideNotification
	// Saves original size of main view.
	var originalViewHeight : CGRect = CGRect()
	var database = Firestore.firestore()
	
	/// Holds chat messages that will display within tableview
	/// - Important: This property calls `createSnapShot` everytime it is updated.
	var chats : [Chats] = []{
		didSet {
			createSnapShot(with: chats)
		}
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		addKeyboardObservers(with: show)
		addKeyboardObservers(with: hide)
		setBackgroundImage()
		setMessageField()
		setSendButton()
		createDataSource()
		originalViewHeight = view.frame
	}
	
	/// Sets aesthetic look for background.
	func setBackgroundImage(){
		backgroundImage.image = UIImage(named: Keys.Images.viewMainBackgroundImage)
		backgroundImage.contentMode = .scaleAspectFill
	}
	
	/// Sets aesthethic look for `messageField`
	func setMessageField(){
		messageField.layer.cornerRadius = 5
		messageField.backgroundColor = .white
	}
	
	/// Sets aesthethic look for `sendButton`
	func setSendButton(){
		sendButton.layer.cornerRadius = 10
	}
	
	func addKeyboardObservers(with name: NSNotification.Name){
		NotificationCenter.default.addObserver(self, selector: #selector(resizeViewWithKeyboardSize(_:)), name: name, object: nil)
	}
	
	func removeKeyboardObservers(with name: NSNotification.Name){
		NotificationCenter.default.removeObserver(self, name: name, object: nil)
	}
	
	@objc func resizeViewWithKeyboardSize(_ notification: Notification){
		let name = notification.name
		
		switch name {
		case show:
			let keyboardRawSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
			let keybaordFrame = keyboardRawSize?.cgRectValue
			guard let keyboardHeight = keybaordFrame?.height else {return}
			let difference = (keyboardHeight / 2 ) + messageField.frame.height
			//view.frame.size.height = difference
			moveTextBoxAndSendButton(amount: difference)
		default:
			//view.frame.size.height = self.originalViewHeight.height
			UIView.animate(withDuration: 0.5) {
				self.communicationStack.transform = .identity
			}
		}
	}
	
	func moveTextBoxAndSendButton(amount:CGFloat){
		UIView.animate(withDuration: 0.5, animations: {
			self.communicationStack.transform = CGAffineTransform(translationX: 0, y: (amount * -1))
			self.loadViewIfNeeded()
		}, completion: nil)
		
	}
	
	//MARK: IBActions
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		guard let messageBody = messageField.text else {return}
		guard let users = Auth.auth().currentUser else {return}
		
		let message = Chats(user: users.email!, message: messageBody, identifer: users.uid)
		
		database.collection(Keys.FireBaseKeys.collection)
		
		print(message)
		messageField.text = nil
	}
	
	@IBAction func logoutButton(_ sender: Any) {
		let firebaseAuth = Auth.auth()
		
		do {
			try firebaseAuth.signOut()
		} catch (let error) {
			print(error.localizedDescription)
		}
		removeKeyboardObservers(with: show)
		removeKeyboardObservers(with: hide)
		performSegue(withIdentifier: Keys.Segues.homeFromChatWindow, sender: nil)
	}
	
	//MARK: - TableView DataSource & Delegate Methods
	
	func createDataSource(){
		dataSource = UITableViewDiffableDataSource<Sections,Chats>(tableView: tableView, cellProvider: { (tableView, indexPath, chats) -> UITableViewCell? in
			let cell = tableView.dequeueReusableCell(withIdentifier: Keys.Cells.chatWindowUniqueIdentifier, for: indexPath) as! ChatsTableViewCell
			
			return cell
		})
	}
	
	func createSnapShot(with chat: [Chats]){
		var snapShot = NSDiffableDataSourceSnapshot<Sections,Chats>()
		snapShot.appendSections([.main])
		snapShot.appendItems(chat, toSection: .main)
		dataSource.apply(snapShot, animatingDifferences: true, completion: nil)
	}
}
