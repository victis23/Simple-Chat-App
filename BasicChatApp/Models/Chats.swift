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
	var identifer :String
	
	func hash(into hasher: inout Hasher){
		hasher.combine(identifer)
	}
}
