//
//  ViewController.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//  Copyright © 2019 FarzadShbfn. All rights reserved.
//

import UIKit
import Styled

// MARK:- ViewController
class ViewController: UIViewController {
	
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var headlineLabel: UILabel!
	@IBOutlet var subtitleLabel: UILabel!
	
	@IBOutlet var separatorViews: [UIView]!
	
	@IBOutlet var colorsTitleLabel: UILabel!
	@IBOutlet var redView: ColorView!
	@IBOutlet var greenView: ColorView!
	@IBOutlet var blueView: ColorView!
	@IBOutlet var goldView: ColorView!
	
	@IBOutlet var imageTitleLabel: UILabel!
	@IBOutlet var profileButton: UIButton!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Just apply colors/fonts/images once, and they will be kept in sync 👍🏼
		
		view.sd.backgroundColor = .background
		view.sd.tintColor = .accent
		
		separatorViews.forEach { $0.sd.backgroundColor = .gray }
		
		// first section
		titleLabel.sd.text = "Font/Localization management";
		titleLabel.sd.textColor = .label
		titleLabel.sd.font = .body(weight: .light)
		
		headlineLabel.sd.text = "Headline of the page"
		headlineLabel.sd.textColor = .label
		headlineLabel.sd.font = .headline
		
		subtitleLabel.sd.text = "Subheadline of the page"
		subtitleLabel.sd.textColor = .secondaryLabel
		subtitleLabel.sd.font = .init(size: .dynamic(.subheadline))
		
		// second section
		colorsTitleLabel.sd.text = "Colors"
		colorsTitleLabel.sd.textColor = .label
		colorsTitleLabel.sd.font = .body(weight: .light)
		
		redView.assign(color: .red)
		greenView.assign(color: .green)
		blueView.assign(color: .blue)
		goldView.assign(color: .gold)
		
		// third section
		imageTitleLabel.sd.text = "Image"
		imageTitleLabel.sd.textColor = .label
		imageTitleLabel.sd.font = .body(weight: .light)
		
		profileButton.sd.setImage(.profile, for: .normal)
		profileButton.sd.setImage(.profileFill, for: .highlighted)
	}
}

// MARK:- ColorView
class ColorView: UIView {
	@IBOutlet var label: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		label.sd.font = .body(weight: .ultraLight)
	}
	
	func assign(color: Color) {
		sd.backgroundColor = color
		label.sd.textColor = .blending(.label, with: color)
	}
}

