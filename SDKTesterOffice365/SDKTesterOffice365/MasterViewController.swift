//
//  MasterViewController.swift
//  SDKTesterOffice365
//
//  Created by Richard diZerega on 11/17/14.
//  Copyright (c) 2014 Richard diZerega. All rights reserved.
//

import UIKit

//var tenant:NSString = "rzna.onmicrosoft.com"
var authority:NSString = "https://login.windows.net/common"
var clientID:NSString = "2908e4e2-c6a4-4829-b065-b15f7ab3ecef"
var redirectURI:NSURL = NSURL(string: "https://orgdna.azurewebsites.net")!

class MasterViewController: UITableViewController, UITableViewDataSource {

    var objects = NSMutableArray()
    var spItems:Array<SPItem> = Array<SPItem>()
    var breadcrumb = [""];

    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet var tblView: UITableView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        
        //remove edit and new buttons
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
        
        //load items
        loadItems("")
    }
    
    func loadItems(id:NSString) -> Void {
        //toggle spinner
        dispatch_async(dispatch_get_main_queue(), {
            self.spinner.center = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
            self.spinner.startAnimating()
        })
        
        //get the items and reload the tableview
        var ctrl:MyFilesController = MyFilesController()
        ctrl.GetFiles(id) { (response:Array<SPItem>?, error:NSError?) in
            self.spItems = response!
            self.tblView.reloadData()
            
            //toggle spinner
            dispatch_async(dispatch_get_main_queue(), {
                self.spinner.hidden = true
                self.spinner.stopAnimating()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func shouldPerformSegueWithIdentifier(identifier: String!, sender: AnyObject!) -> Bool {
        if let indexPath = self.tableView.indexPathForSelectedRow() {
            let item = spItems[indexPath.row] as SPItem
            if (item.Type == "Folder") {
                //toggle spinner and set new title
                dispatch_async(dispatch_get_main_queue(), {
                    self.navItem.title = item.Name
                    self.spinner.center = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
                    self.spinner.hidden = false
                    self.spinner.startAnimating()
                    
                    //clear the items from the table view
                    self.spItems = Array<SPItem>()
                    self.tblView.reloadData()
                })
                
                //reload folder subitems
                var ctrl:MyFilesController = MyFilesController()
                ctrl.GetFiles(item.Id) { (response:Array<SPItem>?, error:NSError?) in
                    self.spItems = response!
                    self.tblView.reloadData()
                    
                    //add the breadcrumb
                    self.breadcrumb.append(item.Name)
                    
                    //hide spinner
                    self.spinner.hidden = true
                    self.spinner.stopAnimating()
                    
                    //add back button if there are now two items in breadcrumb
                    if (self.breadcrumb.count == 2) {
                        var backBtn:UIBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "upFolderLevel:")
                        self.navigationItem.leftBarButtonItem = backBtn
                    }
                }
                return false
            }
            else {
                return true
            }
        }

        return false
    }
    
    func upFolderLevel(sender: UIBarButtonItem){
        breadcrumb.removeLast()
        loadItems(breadcrumb.last!)
        
        //remove the breadcrumb item if this is the last item
        if (breadcrumb.count == 1) {
            self.navigationItem.leftBarButtonItem = nil
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println(segue)
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = spItems[indexPath.row] as SPItem
            (segue.destinationViewController as DetailViewController).detailItem = object
            }
        }
        
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        //get item at index
        let object = spItems[indexPath.row] as SPItem

        //set icon
        let image = UIImage(named: object.GetIcon());
        var imageV : UIImageView = UIImageView(image: image)
        imageV.frame = CGRectMake(10, 0, 48, 48)
        cell.addSubview(imageV)
        
        //set label
        cell.textLabel?.text = "         \(object.Name)"
        var tmpFrame = cell.textLabel?.frame
        tmpFrame?.origin.x += 1000
        cell.frame = tmpFrame!
        
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    /*
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeObjectAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    */
}

