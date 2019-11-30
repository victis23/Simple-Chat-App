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
	
	func keyboardIsHidden(){
		
		self.keyboardHides = NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
			.sink(receiveValue: { (notification) in
				UIView.animate(withDuration: 0.2) {
					self.communicationStack.transform = .identity
				}
			})
	}
	
	func killKeyboardObserver(){
		
		UIView.animate(withDuration: 0.2) {
			self.communicationStack.transform = .identity
		}
		self.keyboardHides?.cancel()
		self.keyboardShowed?.cancel()
		view.endEditing(true)
		messageField.becomeFirstResponder()
	}
}

	
