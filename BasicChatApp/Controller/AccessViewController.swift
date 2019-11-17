//
//  AccessViewController.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/16/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit

class AccessViewController: UIViewController {
	
	@IBOutlet weak var isReg: UILabel!
	var isRegistration : Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
		setView()
    }
	
	func checkIfIsRegistration(is bool: Bool){
		isRegistration = bool
	}
	
	func setView(){
		guard let isRegistrationView = isRegistration else {return}
		if isRegistrationView {
			
		}else{
			
		}
	}
}
