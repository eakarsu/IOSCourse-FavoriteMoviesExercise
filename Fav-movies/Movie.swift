//
//  Movie.swift
//  Fav-movies
//
//  Created by Erol Akarsu on 12/16/15.
//  Copyright © 2015 Erol Akarsu. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Movie)
class Movie: NSManagedObject {

    func setMovieImage(img: UIImage) {
        let data = UIImagePNGRepresentation(img)
        self.imdbImage = data
    }
    
    func getMovieImg() -> UIImage {
        let img = UIImage(data: self.imdbImage!)!
        return img
    }

}
