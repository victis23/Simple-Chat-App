//
//  ExtensionAestheticsChatViewController.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/21/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit

extension ChatViewController {
	
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
}
