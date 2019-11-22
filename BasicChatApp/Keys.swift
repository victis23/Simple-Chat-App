//
//  Keys.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/17/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import Foundation

struct Keys {
	struct Images {
		static var viewMainBackgroundImage = "background"
		static var applogo = "messageIcon"
	}
	struct Segues {
		static var loginScreen = "access"
		static var chatWindow = "chat"
		static var homeFromChatWindow = "homeFromChat"
	}
	struct Cells {
		static var chatWindowUniqueIdentifier = "chats"
	}
	struct FireBaseKeys {
		static var collection = "messages"
		static var sender = "Sender"
		static var messageBody = "MessageBody"
		static var uniqueID = "UniqueId"
		static var uuid = "uuid"
	}
}
