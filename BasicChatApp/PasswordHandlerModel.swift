//
//  PasswordHandlerModel.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/17/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import Foundation

struct Credentials {
	var username: String
	var password: String
	
	static let server = "Simple Chat App"
}

enum KeychainError : Error {
	case noPassword
	case unexpectedPasswordData
	case unhandledError(status: OSStatus)
}
