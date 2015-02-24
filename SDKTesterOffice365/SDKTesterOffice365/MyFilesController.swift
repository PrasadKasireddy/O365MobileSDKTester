//
//  MyFilesController.swift
//  SDKTesterOffice365
//
//  Created by Richard diZerega on 11/19/14.
//  Copyright (c) 2014 Richard diZerega. All rights reserved.
//

import Foundation

typealias SPClientCreatedResponse = (MSSharePointClient?, NSString?) -> Void
typealias ServiceResponse = (Array<SPItem>?, NSError?) -> Void
typealias FileResponse = (NSData?, NSError?) -> Void

class MyFilesController {
    init() {
    }
    
    var DISC_RESOURCE:NSString = "https://api.office.com/discovery/"
    var DISC_SERVICE_ENDPOINT:NSString = "https://api.office.com/discovery/v1.0/me/"
    func EnsureMSSharePointClientCreated(onCompletion:SPClientCreatedResponse) -> Void {
        var er:ADAuthenticationError? = nil
        
        //setup the authentication context for the authority
        var authContext:ADAuthenticationContext = ADAuthenticationContext(authority: authority, error: &er)
        
        //get access token for calling discovery servi e
        authContext.acquireTokenWithResource(DISC_RESOURCE, clientId: clientID, redirectUri: redirectURI, completionBlock: { (discATResult: ADAuthenticationResult!) in
            //validate token exists in response
            if (discATResult.accessToken == nil) {
                onCompletion(nil, "Error getting Discovery Service Access Token")
            }
            else {
                //setup resolver for injection
                var discResolver:MSDefaultDependencyResolver = MSDefaultDependencyResolver()
                var discCred:MSOAuthCredentials = MSOAuthCredentials()
                discCred.addToken(discATResult.accessToken)
                var discCredImpl:MSCredentialsImpl = MSCredentialsImpl()
                discCredImpl.setCredentials(discCred)
                discResolver.setCredentialsFactory(discCredImpl)
                
                //create the discovery client instance
                var client:MSDiscoveryClient = MSDiscoveryClient(url: self.DISC_SERVICE_ENDPOINT, dependencyResolver: discResolver)
                
                //get the services for the user
                var task:NSURLSessionTask = client.getservices().read({(discoveryItems: [AnyObject]!, error: NSError!) -> Void in
                    
                    //check for error and process items
                    if (error == nil) {
                        dispatch_async(dispatch_get_main_queue(), {
                            //cast the discoveryItems as an array of MSDiscoveryServiceInfo
                            var discList = (discoveryItems as Array<MSDiscoveryServiceInfo>)
                            
                            //loop through and find the MyFiles resource
                            var myFilesResource:MSDiscoveryServiceInfo?
                            for discItem in discList
                            {
                                if (discItem.capability == "MyFiles")
                                {
                                    myFilesResource = discItem
                                    break
                                }
                            }
                            
                            //make sure we found the MyFiles resource
                            if (myFilesResource != nil) {
                                var resource:MSDiscoveryServiceInfo = myFilesResource!
                                
                                //get a MyFiles access token
                                authContext.acquireTokenWithResource(resource.serviceResourceId, clientId: clientID, redirectUri: redirectURI, completionBlock: { (shptATResult: ADAuthenticationResult!) in
                                    
                                    //validate token exists in response
                                    if (shptATResult.accessToken == nil && shptATResult.tokenCacheStoreItem == nil && shptATResult.tokenCacheStoreItem.accessToken == nil) {
                                        onCompletion(nil, "Error getting SharePoint Access Token")
                                    }
                                    else {
                                        //get the access token from the result (could be cached)
                                        var accessToken:NSString? = shptATResult.accessToken
                                        if (accessToken == nil) {
                                            accessToken = shptATResult.tokenCacheStoreItem.accessToken
                                        }
                                        
                                        //setup resolver for injection
                                        var shptResolver:MSDefaultDependencyResolver = MSDefaultDependencyResolver()
                                        var spCred:MSOAuthCredentials = MSOAuthCredentials()
                                        spCred.addToken(accessToken)
                                        var spCredImpl:MSCredentialsImpl = MSCredentialsImpl()
                                        spCredImpl.setCredentials(spCred)
                                        shptResolver.setCredentialsFactory(spCredImpl)
                                        
                                        //build SharePointClient
                                        var client:MSSharePointClient = MSSharePointClient(url: resource.serviceEndpointUri, dependencyResolver: shptResolver)
                                        
                                        //return the SharePointClient in callback
                                        onCompletion(client, nil)
                                    }
                                })
                            }
                            else {
                                onCompletion(nil, "Unable to find MyFiles resource")
                            }
                        })
                    }
                    else {
                        onCompletion(nil, "Error calling Discovery Service")
                    }
                })
                
                task.resume()
            }
        })
    }
    
    
    func GetFiles(id:NSString, onCompletion:ServiceResponse) -> Void {
        EnsureMSSharePointClientCreated() { (client:MSSharePointClient?, error:NSString?) in
            
            //check for null client
            if (client != nil) {
                var spClient:MSSharePointClient = client!
                
                //determine if we load root or a subfolder
                if (id == "") {
                    //get the files using SDK
                    var task:NSURLSessionTask = spClient.getfiles().read({ (items: [AnyObject]!, error: NSError!) -> Void in
                        if (error == nil) {
                            dispatch_async(dispatch_get_main_queue(), {
                                var list = (items as Array<MSSharePointItem>)
                                var spItems:Array<SPItem> = self.ConvertToSPItemArray(list)
                                onCompletion(spItems, nil)
                            })
                        }
                        else {
                            println("Error: \(error)")
                        }
                    })
                    task.resume()
                }
                else {
                    //get the files using SDK
                    var task:NSURLSessionTask = spClient.getfiles().getById(id).asFolder().getchildren().read({ (items: Array<AnyObject>!, error: NSError!) -> Void in
                        if (error == nil) {
                            dispatch_async(dispatch_get_main_queue(), {
                                var list = (items as Array<MSSharePointItem>)
                                var spItems:Array<SPItem> = self.ConvertToSPItemArray(list)
                                onCompletion(spItems, nil)
                            })
                        }
                        else {
                            println("Error: \(error)")
                        }
                    })
                    task.resume()
                }
            }
            else {
                println("Error: \(error)")
            }
        }
    }

    func GetFiles(onCompletion:ServiceResponse) -> Void {
        GetFiles("", onCompletion)
    }
    
    func GetFileContent(id: NSString, onCompletion:FileResponse) {
        
        //ensure client created
        EnsureMSSharePointClientCreated() { (client:MSSharePointClient?, error:NSString?) in
            //check for null client
            if (client != nil) {
                var spClient:MSSharePointClient = client!
                
                //get the file content using SDK
                spClient.getfiles().getById(id).asFile().getContent({ (data: NSData!, er: NSError!) -> Void in
                    onCompletion(data, nil)
                }).resume()
            }
            else {
                println("Error: \(error)")
            }
        }
    }
    
    func ConvertToSPItemArray(items: Array<MSSharePointItem>) -> Array<SPItem>
    {
        var spItems:Array<SPItem> = Array<SPItem>()
        for item in items
        {
            var spItem:SPItem = SPItem(name: item.name, type: item.type, id: item.id)
            if (spItem.Type.lowercaseString == "folder" ||
                spItem.Name.lowercaseString.rangeOfString(".png") != nil ||
                spItem.Name.lowercaseString.rangeOfString(".jpg") != nil ||
                spItem.Name.lowercaseString.rangeOfString(".gif") != nil) {
                    spItems.append(spItem)
            }
        }
        return spItems
    }
}