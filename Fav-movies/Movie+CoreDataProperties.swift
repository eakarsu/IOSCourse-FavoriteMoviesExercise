//
//  Movie+CoreDataProperties.swift
//  Fav-movies
//
//  Created by Erol Akarsu on 12/16/15.
//  Copyright © 2015 Erol Akarsu. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Movie {

    @NSManaged var movieTitle: String?
    @NSManaged var imdbURL: String?
    @NSManaged var myDescription: String?
    @NSManaged var imdbPlotDescription: String?
    @NSManaged var imdbImage: NSData?

}
