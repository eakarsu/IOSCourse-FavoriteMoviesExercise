//
//  MovieDetailsVC.swift
//  Fav-movies
//
//  Created by Erol Akarsu on 12/17/15.
//  Copyright © 2015 Erol Akarsu. All rights reserved.
//

import UIKit
import CoreData

class MovieDetailsVC: UIViewController {

    
    @IBOutlet weak var imdbImage: UIImageView!
    
    
    
    @IBOutlet weak var movieTitle: UITextField!
    
    
    @IBOutlet weak var imdbURL: UITextField!
    
    
    
    @IBOutlet weak var myDescription: UITextView!
    @IBOutlet weak var imdbPlotDescription: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func configureMovie (selectedMovie:Movie){
        //imdbPlotDescription.text = selectedMovie.imdbPlotDescription
        imdbImage.image = selectedMovie.getMovieImg()
        movieTitle.text = selectedMovie.movieTitle
        imdbURL.text = selectedMovie.imdbURL
    }
    
    override func viewDidAppear(animated: Bool) {
       
    } 

    
}
