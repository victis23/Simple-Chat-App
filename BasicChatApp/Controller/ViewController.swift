//
//  ViewController.swift
//  BasicChatApp
//
//  Created by Scott Leonard on 11/16/19.
//  Copyright © 2019 DuhMarket. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	//MARK: IBOutlets
	@IBOutlet weak var registerButton: UIButton!
	@IBOutlet weak var loginButton: UIButton!
	@IBOutlet weak var backGroundImage: UIImageView!
	@IBOutlet weak var iconImage: UIImageView!
	
	// MARK: - Instance State
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupBackGroundAesthetics()
		setButtonAesthetics()
		setupIconImage()
	}
	
	// MARK: - Instance Methods
	
	/// Sets opacity and background for view controller.
	func setupBackGroundAesthetics(){
		backGroundImage.alpha = 0.8
		backGroundImage.image = UIImage(named: Keys.Images.viewMainBackgroundImage)
		backGroundImage.contentMode = .scaleAspectFill
	}
	
	/// Sets up look of buttons for view controller.
	func setButtonAesthetics(){
		var count = 0
		[registerButton,loginButton,].forEach({
			$0?.layer.cornerRadius = 5
			$0?.layer.shadowOpacity = 0.2
			$0?.layer.shadowOffset = CGSize(width: 0, height: 1.0)
			$0?.tag = count
			count += 1
		})
	}
	
	/// Sets up logo image.
	func setupIconImage(){
		iconImage.image = UIImage(named: Keys.Images.applogo)
		iconImage.contentMode = .scaleAspectFit
	}
	
	// MARK: IBActions
	
	@IBAction func loginButtonSelected(_ sender: UIButton) {
		switch sender.tag {
		case 1:
			performSegue(withIdentifier: Keys.Segues.loginScreen, sender: sender.tag)
		default:
			performSegue(withIdentifier: Keys.Segues.loginScreen, sender: sender.tag)
		}
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == Keys.Segues.loginScreen {
			let controller = segue.destination as! AccessViewController
			guard let buttonTag = sender as? Int else {return}
			
			switch buttonTag {
			case 1:
				controller.checkIfIsRegistration(is: false)
			default:
				controller.checkIfIsRegistration(is: true)
			}
		}
	}
	
	
}

