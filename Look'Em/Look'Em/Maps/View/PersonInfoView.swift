//
//  PersonInfoView.swift
//  Look'Em
//
//  Created by Welcome on 12/16/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import Foundation

class PersonInfoView: UIView {
    var person: Person? {
        didSet {
            name?.text = person?.name
            status?.text = person?.status
            status?.layer.cornerRadius = 10
            status?.clipsToBounds = true
            distance?.text = "\(person?.location?.disTance(to: DataManager.shared.myLocation) ?? -1) m"
            genderImage?.image = person?.sex?.icon
        }
    }
    
    @IBOutlet weak var genderImage: UIImageView?
    @IBOutlet weak var name: UILabel?
    @IBOutlet weak var status: UILabel?
    @IBOutlet weak var distance: UILabel?
    
    @IBAction func inviTapped(_ sender: Any) {
        self.didTapHander?()
    }
    
    open var didTapHander: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
   
    
    func setup() {
        let view = Bundle.main.loadNibNamed("PersonInfoView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        view.isUserInteractionEnabled = true
        self.addSubview(view)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTap))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func didTap() {
        self.didTapHander?()
    }
}
