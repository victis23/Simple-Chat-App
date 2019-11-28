//
//  Messages.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/17/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import Foundation

struct Chats : Hashable {
	var user : String
	var message: String
	var userIdentifier :String?
	var timeStamp : String
	
	var identifier : UUID {
		guard let userIdentifier = userIdentifier else {fatalError()}
		let id = UUID(uuidString: userIdentifier)
		guard let userID = id else {return UUID()}
		return userID
	}
	
	func hash(into hasher: inout Hasher){
		hasher.combine(identifier)
	}
}
