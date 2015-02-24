 //
//  DetailViewController.swift
//  SDKTesterOffice365
//
//  Created by Richard diZerega on 11/17/14.
//  Copyright (c) 2014 Richard diZerega. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var imgView: UIImageView!
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let item: SPItem = self.detailItem as? SPItem {
            //show the spinner and hide the table
            dispatch_async(dispatch_get_main_queue(), {
                self.navItem.title = item.Name
                self.navItem.backBarButtonItem?.title = "FOO"
                self.spinner.center = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
                self.spinner.startAnimating()
            })
            
            //get file content
            var ctrl:MyFilesController = MyFilesController()
            ctrl.GetFileContent(item.Id) { (response:NSData?, error:NSError?) in
                var img:UIImage = UIImage(data:response!)!
                self.imgView.image = img
                println("image set")
                
                //hide spinner
                dispatch_async(dispatch_get_main_queue(), {
                    self.spinner.hidden = true
                    self.spinner.stopAnimating()
                })
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        //self.configureView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

