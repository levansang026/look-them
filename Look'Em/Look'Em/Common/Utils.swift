//
//  Utils.swift
//  Look'Em
//
//  Created by Welcome on 12/16/17.
//  Copyright © 2017 Le Vu Hoai An. All rights reserved.
//

import Foundation

extension UIImage {
    func changeSize(to edgeSize: Double) -> UIImage {
        
        
        // Figure out what our orientation is, and use that to form the rectangle
        let newSize = CGSize(width: CGFloat(edgeSize), height: CGFloat(edgeSize))
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
