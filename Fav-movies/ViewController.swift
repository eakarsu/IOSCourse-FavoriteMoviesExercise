//
//  ViewController.swift
//  Fav-movies
//
//  Created by Erol Akarsu on 12/16/15.
//  Copyright © 2015 Erol Akarsu. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var movieTableView: UITableView!
    var movies = [Movie]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        movieTableView.delegate = self
        movieTableView.dataSource = self  
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "cellSubmitSegue") {
            print ("preparing move")
            if let selectedIndex = self.movieTableView.indexPathForCell(sender as! UITableViewCell){
                let svc = segue.destinationViewController as! MovieDetailsVC
                print ("selected : \(selectedIndex.row)")
                svc.configureMovie(movies[selectedIndex.row])
            }
         }
    }

 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        fetchAndSetResults()
        movieTableView.reloadData()
    } 
    
    func fetchAndSetResults() {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest  = NSFetchRequest(entityName: "Movie")
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            self.movies = results as! [Movie]
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell") as? MovieCell {
            
            let recipe = movies[indexPath.row]
            cell.configureCell(recipe)
            return cell
        } else {
            return MovieCell()
        }
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }


}

