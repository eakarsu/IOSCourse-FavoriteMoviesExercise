//
//  MovieCell.swift
//  Fav-movies
//
//  Created by Erol Akarsu on 12/16/15.
//  Copyright © 2015 Erol Akarsu. All rights reserved.
//

import UIKit

class MovieCell: UITableViewCell {

    @IBOutlet weak var imdbImage: UIImageView!
    
    
    @IBOutlet weak var movieTitle: UITextField!
    
    
    @IBOutlet weak var imdbURL: UITextField!
    
    @IBOutlet weak var myDescription: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(movie: Movie) {
        
        movieTitle.text = movie.movieTitle
        imdbURL.text = movie.imdbURL
        myDescription.text = movie.myDescription
        imdbImage.image = movie.getMovieImg()
    }
    
}
