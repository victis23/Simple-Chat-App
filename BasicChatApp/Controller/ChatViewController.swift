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

class ChatViewController: UIViewController, ObservableObject {
	
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
	
	// Names used to identify Keyboard events.
	var show : NSNotification.Name = UIResponder.keyboardDidShowNotification
	var hide : NSNotification.Name = UIResponder.keyboardDidHideNotification
	let shrink : NSNotification.Name = NSNotification.Name(rawValue: "shrink")
	var shrinkSubscriber : AnyCancellable?
	var shrinkCounter = 0
	
	// Saves original size of main view.
	var originalTableViewFrame : CGRect = CGRect()
	var database = Firestore.firestore()
	var subscriber : AnyCancellable?
	var future : AnyPublisher<QuerySnapshot,Error>!
	
	/// Holds chat messages that will display within tableview
	/// - Important: This property calls `createSnapShot` everytime it is updated.
	var chats : [Chats] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		aestheticsBundle()
		createDataSource()
		createFireStoreServerObserver()
	}
	
	func aestheticsBundle(){
		originalTableViewFrame = tableView.frame
		addKeyboardObservers(with: show)
		addKeyboardObservers(with: hide)
		addShrinkTableViewFrameObserver()
		setBackgroundImage()
		setMessageField()
		setSendButton()
		//		tableView.keyboardDismissMode = .onDrag
	}
	
	//MARK: - TableView DataSource & Delegate Methods
	
	func createDataSource(){
		dataSource = UITableViewDiffableDataSource<Sections,Chats>(tableView: tableView, cellProvider: { (tableView, indexPath, chats) -> UITableViewCell? in
			let cell = tableView.dequeueReusableCell(withIdentifier: Keys.Cells.chatWindowUniqueIdentifier, for: indexPath)
			cell.textLabel?.text = chats.message
			cell.textLabel?.textColor = .white
			NotificationCenter.default.post(name: self.shrink, object: nil)
			return cell
		})
		
	}
	
	func createSnapShot(with chat: [Chats]){
		var snapShot = NSDiffableDataSourceSnapshot<Sections,Chats>()
		snapShot.appendSections([.main])
		snapShot.appendItems(chat, toSection: .main)
		dataSource.apply(snapShot, animatingDifferences: false) {
			self.shrinkCounter += 1
		}
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
		createFireStoreServerObserver()
		messageField.text = nil
	}
	
	func createFireStoreServerObserver(){
		future = Future<QuerySnapshot,Error> { [weak self](promise) in
			self?.database.collection(Keys.FireBaseKeys.collection).addSnapshotListener { (snapshot, error) in
				if let error = error {
					promise(.failure(error))
					print(error.localizedDescription)
				}
				if let snapshot = snapshot {
					promise(.success(snapshot))
					self?.getUpdates()
				}
			}
		}
		.eraseToAnyPublisher()
	}
	
	func getUpdates(){
		subscriber = future.sink(receiveCompletion: { (completionError) in
			switch completionError {
			case .failure(let internalError):
				print(internalError.localizedDescription)
			case .finished:
				break
			}
		}, receiveValue: { [weak self](incomingSnapshot) in
			self?.retrieveDataFromDatabase(with: incomingSnapshot)
		})
	}
	
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
		subscriber?.cancel()
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
}


