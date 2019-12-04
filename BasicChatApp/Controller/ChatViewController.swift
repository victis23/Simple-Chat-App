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
import Combine
import FacebookLogin

/// This collection handles all chat events saved to the Google FireBase database after user authentification.
class ChatViewController: UIViewController, ObservableObject, UITableViewDelegate {
	
	// Type used to define sections in diffable datasource for tableview.
	enum Sections {
		case main
	}
	
	//MARK: - View Controller Property List Begins | IBOutlets & Class Properties
	
	@IBOutlet weak var communicationStack: UIStackView!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var backgroundImage: UIImageView!
	@IBOutlet weak var sendButton: UIButton!
	@IBOutlet weak var messageField: UITextView!
	
	// DataSource
	var dataSource : UITableViewDiffableDataSource<Sections,Chats>!
	
	var appDelegate = UIApplication.shared.delegate as! AppDelegate
	
	
	// Google Firestore Firebase Instance.
	var database = Firestore.firestore()
	var isFacebookSignIn : Bool = false
	
	
	// MARK: Combine Properties | Publishers .... Subscribers
	
	@Published var dataBaseSnapShot : QuerySnapshot!
	var future : AnyPublisher<QuerySnapshot,Never>!
	
	var subscriber : AnyCancellable?
	var publicSubscriber : AnyCancellable?
	var keyboardShowed : AnyCancellable?
	var keyboardHides : AnyCancellable?
	
	// A timestamp sorted list of messages.
	var chats : [Chats] = []
	
	//MARK: - State
	
	override func viewDidLoad() {
		super.viewDidLoad()
		aestheticsBundle()
		createDataSource()
		getValuesFromSubscriber()
		createFireStoreServerObserver()
		tableView.delegate = self
	}
	
	func aestheticsBundle(){
		setBackgroundImage()
		setMessageField()
		setSendButton()
	}
}

//MARK: - Firestore Methods & Actions

extension ChatViewController {
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		
		/// Type that sets uniqueID for user entries into database.
		struct UuidCreator {
			let identifier = UUID()
		}
		
		guard let messageBody = messageField.text else {return}
		guard let users = Auth.auth().currentUser else {return}
		var email : String = ""
		
		// Since fb users will not be providing an email, their username is used as a placeholder instead.
		if isFacebookSignIn {
			guard let username = users.displayName else {return}
			email = "Facebook - \(username)"
		}else{
			guard let userEmail = users.email else {return}
			email = userEmail
		}
		
		// Object that holds our UUID.
		let tempObjectIDCreator = UuidCreator()
		let stringID = "\(tempObjectIDCreator.identifier)"
		
		// Timestamp must have time listed in long format for accuracy.
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .long
		let timeStamp = formatter.string(from: Date())
		
		createDocument(user: email, userId: stringID, messageBody: messageBody, timeStamp: timeStamp)
		// Reset our message field in preperation for next message.
		messageField.text = nil
	}
	
	//MARK: Create FireStore Document
	
	/// Method gathers data provided by user and bundles it into a new document for the database.
	/// - Note: The document data is composed of 4 string objects.
	func createDocument(user email: String, userId: String, messageBody:String, timeStamp:String){
		
		let collection = database.collection(Keys.FireBaseKeys.collection)
		collection.addDocument(data: [
			Keys.FireBaseKeys.sender : email,
			Keys.FireBaseKeys.messageBody : messageBody,
			Keys.FireBaseKeys.uniqueID : userId,
			Keys.FireBaseKeys.timeStamp : timeStamp
		]) { (error) in
			guard let error = error else {return}
			print(error.localizedDescription)
		}
		/*
		_ = database.collection("NewCollection").document("SourceDoc").collection("Collection2").addDocument(data: ["Testing":"This is a test"]) { (error) in
			if let error = error {
				print(error.localizedDescription)
			}
		}
		*/
	}
	
	// MARK: Create FireStore Observer
	func createFireStoreServerObserver(){
		
		/// Creates an observer for our Database. This method will be called whenever there is an update to our remote database.
		database.collection(Keys.FireBaseKeys.collection).addSnapshotListener { (snapshot, error) in
			if let error = error {
				print(error.localizedDescription)
			}
			// After snapshot is unwrapped it's passed to a publisher who's subscriber assigns the value of our snapshot to a class property. This was done simply for combine practice seeing that we could have simply assigned the value directly to the property which also happens to be a publisher itself here.
			guard let snapshot = snapshot else {return}
			self.future = Just(snapshot)
				.eraseToAnyPublisher()
			
			self.subscriber = self.future
				.sink(receiveValue: { (snap) in
					self.dataBaseSnapShot = snap
				})
		}
	}
	
	/// Creates an observer that is called whenever the value of `dataBaseSnapShot` is changed.
	func getValuesFromSubscriber(){
		
		publicSubscriber = $dataBaseSnapShot
			.sink { (capturedSnapShotValue) in
				guard let capturedSnapShotValue = capturedSnapShotValue else {return}
				self.retrieveDataFromDatabase(with: capturedSnapShotValue)
		}
	}
	
	/// Simple Method without using combine framework kept here just for reference.
	/*
	func createFireStoreServerObserver(){
	database.collection(Keys.FireBaseKeys.collection).addSnapshotListener { (snapshot, error) in
	if let error = error {
	print(error.localizedDescription)
	}
	guard let snapshot = snapshot else {return}
	self.retrieveDataFromDatabase(with: snapshot)
	}
	}
	*/
	
	//MARK: Retrieve Values from FireStore Database
	
	/// Method retrieves updates from firebase document and assigns them to a `Chats` object which is sorted and placed into a ordered collection.
	/// - Note: The values retrieved from our document are hashed and duplicates are removed with `removeDuplicates` collection.
	/// -	Items are downcasted back into `String` types.
	/// - 	Items are sorted from earliest to latest and placed within an ordered collection that must conform to `Hashable` protocol.
	/// -	Items are used for argument in `createSnapShot(with:)` call.
	func retrieveDataFromDatabase(with snapshot: QuerySnapshot){
		
		let dbSnapShot = snapshot.documents
		
		//		self.chats.removeAll()
		
		//Uses the collection item's unique identifier to remove duplicates.
		// This works outside the scope of this function however it needs to be placed here so that when the server gets erased it removes the erased entries without having to restart the session.
		var removeDuplicates : Set<Chats> = []
		
		dbSnapShot.forEach({
			let databaseData = $0.data()
			
			removeDuplicates.insert(Chats(
				user: databaseData[Keys.FireBaseKeys.sender] as! String,
				message: databaseData[Keys.FireBaseKeys.messageBody] as! String,
				userIdentifier: databaseData[Keys.FireBaseKeys.uniqueID] as? String,
				timeStamp: databaseData[Keys.FireBaseKeys.timeStamp] as! String
			))
		})
		
		chats = removeDuplicates.map({$0})
		chats.sort(by: {$0.timeStamp < $1.timeStamp})
		createSnapShot(with: chats)
	}
	
	
	
	//MARK: - TableView DataSource & Delegate Methods
	
	/// Creates instance of `UITableViewDiffableDataSource`
	///	-	`SectionIdentifierType = Sections`
	/// -	`ItemIdentifierType = Chats`
	/// -	Important: Visual of table is affected by user authentification method.
	func createDataSource(){
		dataSource = UITableViewDiffableDataSource<Sections,Chats>(tableView: tableView, cellProvider: { (tableView, indexPath, chats) -> UITableViewCell? in
			
			guard let currentSender = Auth.auth().currentUser else {fatalError()}
			
			let cell = tableView.dequeueReusableCell(withIdentifier: Keys.Cells.chatWindowUniqueIdentifier, for: indexPath)
			
			func compareValues(isFacbook:Bool){
				let identifer = isFacbook ? "Facebook - \(currentSender.displayName!)" : currentSender.email
				
				if chats.user != identifer {
					[cell.textLabel, cell.detailTextLabel].forEach({
						$0?.textColor = .black
					})
				}else{
					[cell.textLabel, cell.detailTextLabel].forEach({
						$0?.textColor = .white
					})
				}
			}
			
			if self.isFacebookSignIn {
				cell.textLabel?.text = currentSender.displayName
				compareValues(isFacbook: true)
			}else{
				cell.textLabel?.text = chats.user
				compareValues(isFacbook: false)
			}
			cell.detailTextLabel?.text = chats.message
			return cell
		})
		
	}
	
	/// Creates source of TRUTH for our datasource property.
	/// -	Note: The position and size of the tableview is determined in this method as well. Breaks SOLID?
	func createSnapShot(with chat: [Chats]){
		var snapShot = NSDiffableDataSourceSnapshot<Sections,Chats>()
		snapShot.appendSections([.main])
		snapShot.appendItems(chat, toSection: .main)
		
		dataSource.apply(snapShot, animatingDifferences: false) {
			
			if self.chats.count >= 5 {
				self.tableView.scrollToRow(at: IndexPath(row: self.chats.count - 1, section: 0), at: .bottom, animated: true)
				self.appDelegate.keyboardManager(isOn: true)
				if self.chats.count == 5 {
					self.killKeyboardObserver()
				}
			}else{
				self.appDelegate.keyboardManager(isOn: false)
				self.keyboardIsPresent()
				self.keyboardIsHidden()
			}
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	//MARK: - Navigation — Logout
	
	/// Logs user out of Google FireBase & Facebook if they used that method for login.
	@IBAction func logoutButton(_ sender: Any) {
		
		let firebaseAuth = Auth.auth()
		
		do {
			try firebaseAuth.signOut()
			
			let facebookLoginManager = LoginManager()
			facebookLoginManager.logOut()
			
		} catch (let error) {
			print(error.localizedDescription)
		}
		
		// Terminates the subscription to Google Firebase updates.
		publicSubscriber?.cancel()
		// Returns user to login screen.
		performSegue(withIdentifier: Keys.Segues.homeFromChatWindow, sender: nil)
	}
}


