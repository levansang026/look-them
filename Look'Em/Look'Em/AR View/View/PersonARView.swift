//
//  PersonARView.swift
//  Look'Em
//
//  Created by Le Vu Hoai An on 12/16/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import UIKit

protocol PersonARViewDelegate: class {
    func didTapFindButton(to latitude: Double, longtitude: Double)
}

open class PersonARView: UIView {

    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var sex: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var findButton: UIButton!
    
    weak var delegate: PersonARViewDelegate?
    
    @IBAction func tapFindButton(_ sender: Any) {
        delegate?.didTapFindButton(to: (person?.location?.latitude)!, longtitude: (person?.location?.longitude)!)
    }
    
    var person: Person? {
        didSet {
            avatar?.image = #imageLiteral(resourceName: "avatar")
            name?.text = person?.name
            status?.text = person?.status
            if let dis = person?.distance?.rounded() {
                distance.text = "\(dis) m"
            }
            sex?.image = person?.sex?.icon
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
            self.addGestureRecognizer(tapGesture)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    fileprivate func setup() {
        let view = Bundle.main.loadNibNamed("PersonARView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        addSubview(view)
    }
    
    @objc func tapHandler() {
        print("TAP")
        UIView.animate(withDuration: 0.1) { [weak self] in
            guard let strongSelf = self else {return}
            if strongSelf.status.isHidden {
                strongSelf.status.isHidden = false
                strongSelf.findButton.isHidden = false
                //strongSelf.avatar.alpha = 0.5
            } else {
                strongSelf.status.isHidden = true
                strongSelf.findButton.isHidden = true
                //strongSelf.avatar.alpha = 1
            }
        }
        
        self.layoutIfNeeded()
    }
}
