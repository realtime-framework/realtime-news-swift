//
//  DataObject.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 09/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit


var contentsOnDiskData:NSMutableDictionary = NSMutableDictionary()
var menuOnDiskData:NSMutableDictionary = NSMutableDictionary()

class DataObject: NSObject {
    
    var monthYear:NSString?
    var type:NSString?
    var timestamp:NSString?
    var url:NSString?
    var body:NSString?
    var onDiskData:NSString?
    var image:NSData?
    var imageURL:String?
    var textDescription:NSString?
    var title:NSString?
    var tag:NSString?
    
    var imageLoader:ImageLoader?
    var date:NSString?
    var onDisk:Bool?
    var isNew:Bool?
    var isUpdated:Bool?
    var isOffline:Bool?
    var data:NSDictionary?
    var callback: (NSData?) -> Void
    var callbackIsSet:Bool = false;
    var cell:DataTableViewCell?
    
    override init() {
        self.callback = {(img:NSData?)in }
        super.init()
    }
    
    
    init(tag:NSString?,type:NSString?)
    {
        self.callback = {(img:NSData?)in }
        self.type = type
        self.tag = tag
        super.init()
    }
    
    init(desc:NSString?, img:NSData?, onDisk:Bool?, pDate:NSString?)
    {
        self.callback = {(img:NSData?)in }
        self.textDescription = desc
        self.date = pDate
        self.image = img
        self.onDisk = onDisk
        super.init()
    }
    
    func updateItem(item:DataObject){
        self.type = item.type
        self.timestamp = item.timestamp
        self.url = item.url
        self.body = item.body
        self.image = item.image
        self.textDescription = item.textDescription
        self.title = item.title
        self.tag = item.tag
    }
    
    class func writeMenuOndisk() -> Bool{
        let path = DataObject.applicationDocumentsDirectory()+"/ONDISKMENU"
        return menuOnDiskData.writeToFile(path, atomically: true)
    }
    
    class func resetMenuOnDisk() -> Bool{
        let path = DataObject.applicationDocumentsDirectory()+"/ONDISKMENU"
        
        return menuOnDiskData.writeToFile(path, atomically: true)
    }
    
    class func MenuOnDisk() -> NSMutableDictionary?{
        let path = DataObject.applicationDocumentsDirectory()+"/ONDISKMENU"
        var temp:NSMutableDictionary? = NSMutableDictionary(contentsOfFile: path)
        if temp != nil
        {
            menuOnDiskData = temp!
            return menuOnDiskData
        }else
        {
            return nil
        }
    }
    
    class func writeContentOndisk() -> Bool{
        let path = DataObject.applicationDocumentsDirectory()+"/ONDISK"
        return contentsOnDiskData.writeToFile(path, atomically: true)
    }
    
    class func resetContentsOnDisk() -> Bool{
        let path = DataObject.applicationDocumentsDirectory()+"/ONDISK"
        
        return contentsOnDiskData.writeToFile(path, atomically: true)
    }
    
    class func contentsOnDisk() -> NSMutableDictionary?{
        let path = DataObject.applicationDocumentsDirectory()+"/ONDISK"
        var temp:NSMutableDictionary? = NSMutableDictionary(contentsOfFile: path)
        if temp != nil
        {
            contentsOnDiskData = temp!
            return contentsOnDiskData
        }else
        {
            return nil
        }
    }
    
    func storeOnDisk() -> Bool
    {
        if self.type == nil || self.timestamp == nil
        {
            return false
        }
        
        let path = DataObject.applicationDocumentsDirectory()
        return self.data!.writeToFile(path + "/"+self.type!+"-"+self.timestamp!+".item", atomically: true)
    }
    
    
    func removeFromDisk()
    {
        let filemanager:NSFileManager = NSFileManager.defaultManager()
        let path = DataObject.applicationDocumentsDirectory()
        
        filemanager.removeItemAtPath(path + "/"+self.type!+"-"+self.timestamp!+".item", error: nil)
        filemanager.removeItemAtPath(path + "/"+self.type!+"-"+self.timestamp!+".data", error: nil)
        filemanager.removeItemAtPath(path + "/"+self.type!+"-"+self.timestamp!+".body", error: nil)
    }
    
    class func getFromDiskWithType(type:NSString, timestamp:NSString) -> DataObject?
    {
        var temp:DataObject = DataObject()
        temp.type = type
        temp.timestamp = timestamp
        
        let path = DataObject.applicationDocumentsDirectory()
        
        var file:String = "\(path)/\(temp.type!)-\(temp.timestamp!).item"

        let val:NSDictionary? = NSDictionary(contentsOfFile: file)
        if val == nil
        {
            return nil
        }
        return DataObject.loadDataObjectFromDictionary(val!)
    }
    
    class func getMenuFromDiskWithType(type:NSString, tag:NSString) -> DataObject?
    {
        var temp:DataObject = DataObject()
        temp.type = type
        temp.tag = tag
        
        let path = DataObject.applicationDocumentsDirectory()
        
        var file:String = "\(path)/\(temp.type!)-\(temp.tag!).item"
        
        let val:NSDictionary? = NSDictionary(contentsOfFile: file)
        if val == nil
        {
            return nil
        }
        return DataObject.loadDataObjectFromDictionary(val!)
    }

    
    
    class func loadDataObjectFromDictionary(val:NSDictionary) -> DataObject
    {
        var img:NSData?
        var item:DataObject?
        
        let desc = val.objectForKey("Description") as? String
        if desc != nil
        {
            item = DataObject(desc: val.objectForKey("Description") as String, img: img, onDisk: false, pDate: Utils.convertTimeStamp(val.objectForKey("Timestamp")!.doubleValue))
            item!.monthYear = val.objectForKey("MonthYear") as? NSString
            item!.timestamp = val.objectForKey("Timestamp") as? NSString
            item!.data = val
            item!.type = val.objectForKey("Type") as? NSString
            
            if val.objectForKey("URL") != nil
            {
                item!.url = val.objectForKey("URL") as String!
            }
            
            if val.objectForKey("Body") != nil
            {
                item!.body = val.objectForKey("Body") as String!
                item!.url = "about:blank"
            }
            
            var ponDiskData:NSData? =  NSData(contentsOfFile: "\(DataObject.applicationDocumentsDirectory())/\(item!.type!)-\(item!.timestamp!).onDiskData")
            
            if ponDiskData?.length > 0
            {
                item!.onDiskData = NSString(data: ponDiskData!, encoding: NSUTF8StringEncoding)
                item!.onDisk = true
            }
            
            item!.title = val.objectForKey("Title") as String
            item!.tag = val.objectForKey("Tag") as String
        }
        else
        {
            item = DataObject(tag: val.objectForKey("Tag") as String, type: val.objectForKey("Type") as String)
        }
        return item!
    }
    
    
    class func applicationDocumentsDirectory() -> String
    {
        return NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
    }
    
    
        
}









