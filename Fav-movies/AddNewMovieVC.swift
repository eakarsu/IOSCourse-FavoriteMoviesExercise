//
//  AddNewMovieVC.swift
//  Fav-movies
//
//  Created by Erol Akarsu on 12/16/15.
//  Copyright © 2015 Erol Akarsu. All rights reserved.
//

import UIKit
import CoreData

class AddNewMovieVC: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
       
    
    @IBOutlet weak var movieTitle: UITextField!
    @IBOutlet weak var imdbURL: UITextField!
    
    
    @IBOutlet weak var myDescription: UITextField!
    
    
    @IBOutlet weak var imdbPlotDescription: UITextField!
    
    
    @IBOutlet weak var imdbImage: UIImageView!
    
    @IBOutlet weak var addMovieButton: UIButton!

    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imdbImage.layer.cornerRadius = 4.0
        imdbImage.clipsToBounds = true
         
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imdbImage.image = image
    }
    
    @IBAction func addImage(sender: AnyObject!) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func createMovie(sender: AnyObject!) {
        if let title = movieTitle.text where title != "" {
            
            let app = UIApplication.sharedApplication().delegate as! AppDelegate
            let context = app.managedObjectContext
            let entity = NSEntityDescription.entityForName("Movie", inManagedObjectContext: context)!
            let movie = Movie(entity: entity, insertIntoManagedObjectContext: context)
            movie.movieTitle = title
            movie.imdbURL = imdbURL.text
            movie.myDescription = myDescription.text
            movie.imdbPlotDescription = imdbPlotDescription.text
            movie.setMovieImage(imdbImage.image!)
            
            context.insertObject(movie)
            
            do {
                try context.save()
            } catch {
                print("Could not save recipe")
            }
            
            self.navigationController?.popViewControllerAnimated(true)
        }

    }
    
}
