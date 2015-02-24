//
//  SPItem.swift
//  SDKTesterOffice365
//
//  Created by Richard diZerega on 11/18/14.
//  Copyright (c) 2014 Richard diZerega. All rights reserved.
//

import Foundation

class SPItem {
    init(name: NSString, type: NSString, id: NSString) {
        Name = name
        Type = type
        Id = id
    }
    
    var Name:NSString
    var Type:NSString
    var Id:NSString
    
    func GetIcon() -> NSString {
        if (self.Type.lowercaseString == "folder")
        {
            return "folder.png"
        }
        else if (self.Name.lowercaseString.rangeOfString(".png") != nil)
        {
            return "png.png"
        }
        else if (self.Name.lowercaseString.rangeOfString(".jpg") != nil)
        {
            return "jpg.png"
        }
        else if (self.Name.lowercaseString.rangeOfString(".gif") != nil)
        {
            return "gif.png"
        }
        else
        {
            return "folder.png"
        }
    }
}