//
//  ExtensionKeyboardChatViewController.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/21/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit

//MARK: - Keyboard Handling Methods


extension ChatViewController {
	
	/// Method creates event subscriber for notification `keyboardDidShowNotification`
	/// - Important: This method is only called when the amount of chat messages on screen is [0,5)
	/// - Note: That the amount the chat box is moved is 100 points less than the height of the keyboard.
	func keyboardIsPresent(){
		
		self.keyboardShowed = NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification).sink { (notification) in
			
			let keyboardRawSizeValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
			let keyboardFrame = keyboardRawSizeValue?.cgRectValue
			guard let keyboardHeight = keyboardFrame?.height else {return}
			
			UIView.animate(withDuration: 0.2) {
				self.communicationStack.transform = CGAffineTransform(translationX: 0, y: (keyboardHeight - 100) * -1)
			}
		}
	}
	
	/// Method returns `comunicationStack` to its original position when the keyboard is no longer being presented on screen.
	func keyboardIsHidden(){
		
		self.keyboardHides = NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
			.sink(receiveValue: { (notification) in
				UIView.animate(withDuration: 0.2) {
					self.communicationStack.transform = .identity
				}
			})
		
	}
	
	/// Method is called once the number of items in `chats` collection is == 5
	func killKeyboardObserver(){
		
		UIView.animate(withDuration: 0.2) {
			self.communicationStack.transform = .identity
		}
		self.keyboardHides?.cancel()
		self.keyboardShowed?.cancel()
		// For a smooth transition between the custom keyboard observing methods and KeyboardIQ the keyboard must be dismissed and recalled.
		view.endEditing(true)
		messageField.becomeFirstResponder()
	}
}

	
