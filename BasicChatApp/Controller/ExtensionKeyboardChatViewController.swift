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
	
	func addKeyboardObservers(with name: NSNotification.Name){
		NotificationCenter.default.addObserver(self, selector: #selector(resizeViewWithKeyboardSize(_:)), name: name, object: nil)
	}
	
	func removeKeyboardObservers(with name: NSNotification.Name){
		NotificationCenter.default.removeObserver(self, name: name, object: nil)
	}
	
	func addShrinkTableViewFrameObserver() {
		
		shrinkSubscriber = NotificationCenter.default.publisher(for: shrink)
			.sink { (notification) in
				if self.shrinkCounter == 1 {
					self.shrinkCounter = 0
					self.tableView.frame.size.height = (self.tableView.frame.height - 230) 
				}
		}
	}
	
	@objc func resizeViewWithKeyboardSize(_ notification: Notification){
		let name = notification.name
		switch name {
		case show:
			let keyboardRawSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
			let keybaordFrame = keyboardRawSize?.cgRectValue
			guard let keyboardHeight = keybaordFrame?.height else {return}
			let difference = (keyboardHeight / 2 ) + messageField.frame.height
			moveTextBoxAndSendButton(amount: difference)
		default:
			UIView.animate(withDuration: 0.2) {
				self.tableView.frame.size.height = self.originalTableViewFrame.height
				self.communicationStack.transform = .identity
			}
			
		}
	}
	
	func moveTextBoxAndSendButton(amount:CGFloat){
		UIView.animate(withDuration: 0.2, animations: {
			self.communicationStack.transform = CGAffineTransform(translationX: 0, y: (amount * -1))
			self.tableView.frame.size.height = self.tableView.frame.height - 230
			self.loadViewIfNeeded()
		}, completion: nil)
		
	}
}
