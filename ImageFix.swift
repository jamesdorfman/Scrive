//
//  ImageFix.swift
//  GoogleVision
//
//  Created by James Dorfman on 2017-08-07.
//  Copyright © 2017 James Dorfman. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func fixOrientation() -> UIImage {
        if self.imageOrientation == UIImageOrientation.up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        if let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        } else {
            return self
        }
    }
}
