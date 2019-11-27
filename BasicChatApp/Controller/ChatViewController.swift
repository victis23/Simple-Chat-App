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
			
			if chats.user != currentSender.email {
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
}

//MARK: - Firestore Methods & Actions

extension ChatViewController {
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		
		guard let messageBody = messageField.text else {return}
		guard let users = Auth.auth().currentUser else {return}
		guard let email = users.email else {return}
		
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .long
		let timeStamp = formatter.string(from: Date())
		
		let collection = database.collection(Keys.FireBaseKeys.collection)
		collection.addDocument(data: [
			Keys.FireBaseKeys.sender : email,
			Keys.FireBaseKeys.messageBody : messageBody,
			Keys.FireBaseKeys.uniqueID : users.uid,
			Keys.FireBaseKeys.timeStamp : timeStamp
		]) { (error) in
			guard let error = error else {return}
			print(error.localizedDescription)
		}
		messageField.text = nil
	}
	
	
	
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
	
	func retrieveDataFromDatabase(with snapshot: QuerySnapshot){
		let snapshot = snapshot.documents
		self.chats.removeAll()
		snapshot.forEach({
			let snapshot = $0.data()
			self.chats.append(Chats(
				user: snapshot[Keys.FireBaseKeys.sender] as! String,
				message: snapshot[Keys.FireBaseKeys.messageBody] as! String,
				userIdentifier: snapshot[Keys.FireBaseKeys.uniqueID] as? String,
				timeStamp: snapshot[Keys.FireBaseKeys.timeStamp] as! String
			))
		})
		let sortedChates = chats.sorted { (value1, value2) -> Bool in
			value1.timeStamp < value2.timeStamp
		}
		createSnapShot(with: sortedChates)
	}
	
	@IBAction func logoutButton(_ sender: Any) {
		
		let firebaseAuth = Auth.auth()
		do {
			try firebaseAuth.signOut()
		} catch (let error) {
			print(error.localizedDescription)
		}
		performSegue(withIdentifier: Keys.Segues.homeFromChatWindow, sender: nil)
	}
}


