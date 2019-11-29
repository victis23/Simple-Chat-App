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

class ChatViewController: UIViewController, ObservableObject, UITableViewDelegate {
	
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
	var publicSubscriber : AnyCancellable?
	
	var database = Firestore.firestore()
	var isFacebookSignIn : Bool = false
	
	// Combine Properties
	var subscriber : AnyCancellable?
	@Published var dataBaseSnapShot : QuerySnapshot!
	var future : AnyPublisher<QuerySnapshot,Never>!
	
	/// Holds chat messages that will display within tableview
	var chats : [Chats] = []
	
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
		
		struct UuidCreator {
			let identifier = UUID()
		}
		
		guard let messageBody = messageField.text else {return}
		guard let users = Auth.auth().currentUser else {return}
		var email : String = ""
		
		if isFacebookSignIn {
			guard let username = users.displayName else {return}
			email = "Facebook Login For \(username)"
		}else{
			guard let userEmail = users.email else {return}
			email = userEmail
		}
		
		// Creates the UUID that will be used for updated our diffable data source.
		let tempObjectIDCreator = UuidCreator()
		let stringID = "\(tempObjectIDCreator.identifier)"
		
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .long
		let timeStamp = formatter.string(from: Date())
		
		createDocument(user: email, userId: stringID, messageBody: messageBody, timeStamp: timeStamp)
		
		messageField.text = nil
	}
	
	//MARK: Create FireStore Document
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
	}
	
	// MARK: Create FireStore Observer
	func createFireStoreServerObserver(){
		
		database.collection(Keys.FireBaseKeys.collection).addSnapshotListener { (snapshot, error) in
			if let error = error {
				print(error.localizedDescription)
			}
			
			guard let snapshot = snapshot else {return}
			
			self.future = Just(snapshot)
				.eraseToAnyPublisher()
			
			self.subscriber = self.future
				.sink(receiveValue: { (snap) in
					self.dataBaseSnapShot = snap
				})
		}
	}
	
	func getValuesFromSubscriber(){
		
		publicSubscriber = $dataBaseSnapShot
			.sink { (capturedSnapShotValue) in
				guard let capturedSnapShotValue = capturedSnapShotValue else {return}
				self.retrieveDataFromDatabase(with: capturedSnapShotValue)
		}
	}
	
	// Simple Method without using combine framework.
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
	func retrieveDataFromDatabase(with snapshot: QuerySnapshot){
		
		let dbSnapShot = snapshot.documents
		
		//		self.chats.removeAll()
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
	
		let sortedChates = chats.sorted { (value1, value2) -> Bool in
			value1.timeStamp < value2.timeStamp
		}
		
		createSnapShot(with: sortedChates)
	}
	
	
	
	//MARK: - TableView DataSource & Delegate Methods
	
	func createDataSource(){
		dataSource = UITableViewDiffableDataSource<Sections,Chats>(tableView: tableView, cellProvider: { (tableView, indexPath, chats) -> UITableViewCell? in
			
			guard let currentSender = Auth.auth().currentUser else {fatalError()}
			
			let cell = tableView.dequeueReusableCell(withIdentifier: Keys.Cells.chatWindowUniqueIdentifier, for: indexPath)
			cell.detailTextLabel?.text = chats.message
			cell.textLabel?.text = chats.user
			
			[cell.textLabel, cell.detailTextLabel].forEach({
				$0?.textColor = .white
			})
			
			if chats.user != currentSender.displayName {
				[cell.textLabel, cell.detailTextLabel].forEach({
					$0?.textColor = .black
				})
			}
			
			return cell
		})
		
	}
	
	func createSnapShot(with chat: [Chats]){
		var snapShot = NSDiffableDataSourceSnapshot<Sections,Chats>()
		snapShot.appendSections([.main])
		snapShot.appendItems(chat, toSection: .main)
		
		dataSource.apply(snapShot, animatingDifferences: false) {
			if self.chats.count > 0 {
				self.tableView.scrollToRow(at: IndexPath(row: self.chats.count - 1, section: 0), at: .bottom, animated: true)
			}
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	//MARK: - Navigation — Logout
	@IBAction func logoutButton(_ sender: Any) {
		
		let firebaseAuth = Auth.auth()
		
		do {
			try firebaseAuth.signOut()
		} catch (let error) {
			print(error.localizedDescription)
		}
		
		// Terminates the subscription.
		publicSubscriber?.cancel()
		
		performSegue(withIdentifier: Keys.Segues.homeFromChatWindow, sender: nil)
	}
}


