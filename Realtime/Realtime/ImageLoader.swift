//
//  ImageLoader.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 04/03/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit

class ImageLoader {
    var item:DataObject
    var img:String
    var data:NSData?
    
    init(item:DataObject, img:String)
    {
        self.item = item
        self.img = img
        self.getImage()
    }
    
    func getImage(){
        {
            do{
                try self.data = NSURLConnection.sendSynchronousRequest(NSURLRequest(URL: NSURL(string: self.item.imageURL!)!), returningResponse: nil)
            }catch{
            
            }
            if self.data != nil{
                self.item.image = NSData(data: self.data!)
                let path = DataObject.applicationDocumentsDirectory()
                self.item.image!.writeToFile("\(path)/\(self.item.type!)-\(self.item.timestamp!).data", atomically: true)
            }
        } ~> {
            if self.item.image != nil{
                self.item.callback(self.item.image!)
            }
        }
    }
    
}
