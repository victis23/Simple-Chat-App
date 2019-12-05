//
//  AuthenticationModel.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 12/5/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FacebookLogin

struct FireBaseUserCreds {
	var username: String
	var password: String
	
	init(username: String, password: String) {
		self.username = username
		self.password = password
	}
}

struct AppleUserCreds {
	var nonce : String
	var idToken : String?
	
	/// Creates a randomized string to be used as unique nonce value.
	static func globalNonceCreator(length:Int = 32)->String{
		
		precondition(length > 0)
		
		let availableCharacters : Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
		
		var result = ""
		var remainingLength = length
		
		while remainingLength > 0 {
			let randoms: [UInt8] = (0..<16).map({_ in
				var random: UInt8 = 0
				let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
				
				if errorCode != errSecSuccess {
					fatalError("Unable to create global nonce: \(errorCode)")
				}
				return random
			})
			
			randoms.forEach({ random in
				
				if length == 0 {
					return
				}
				
				if random < availableCharacters.count {
					result.append(availableCharacters[Int(random)])
					remainingLength -= 1
				}
			})
		}
		
		return result
	}
	
	/// Encripts generated nonce which is assigned to the `request.nonce` property held by device For this App's Bundle.
	func sha256()->String{
		let inputData = Data(nonce.utf8)
		let hashData = SHA256.hash(data: inputData)
		let hashString = hashData.compactMap({
			return String(format: "%02x", $0)
		}).joined()
		return hashString
	}
	
}

struct FacebookUserCreds {
	var accessToken : String
}

struct AuthCredentialToken {
	var authCredUniqueToken : AuthCredential
}
