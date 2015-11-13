//
//  SM.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 09/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit

@objc protocol SMProtocol
{
    var isFiltred:Bool {get set}
    var filter:String  {get set}
    
    optional func didReceivedData(data:NSMutableArray)
    optional func didReceivedItem(item:DataObject)
    optional func didDeleteItem(item:DataObject)
    
    optional func onReconnected()
    optional func onReconnecting()
}

var storage:Storage?
var flag:dispatch_semaphore_t =  dispatch_semaphore_create(1)

class Storage: NSObject {
    var contentsDelegate:SMProtocol?
    var tagsDelegate:SMProtocol?
    var storageRef:StorageRef?
    var contentsTableRef:SM?
    var tagsTableRef:SM?
    
    init(contentsDelegate:SMProtocol, tagsDelegate:SMProtocol)
    {
        
        currentSearchMonth = nil
        scrollLimit = limit
        lastTimestamp = nil
        
        self.contentsDelegate = contentsDelegate
        self.tagsDelegate = tagsDelegate
        
        self.storageRef = StorageRef(APP_KEY, privateKey: nil, authenticationToken: token)
        super.init()
        NSLog("( STORAGE REF )")
        self.contentsTableRef = SM(tableName: TABCONTENTS, storageRef: self.storageRef!)
        self.contentsTableRef!.delegate = self.contentsDelegate
        
        self.tagsTableRef = SM(tableName: TABTAGS, storageRef: self.storageRef!)
        self.tagsTableRef!.delegate = self.tagsDelegate
        
        self.storageRef!.onReconnected({ (storageRef) -> Void in
                currentSearchMonth = nil
                scrollLimit = limit
                lastTimestamp = nil
                
                isConnected = true
                self.contentsDelegate?.onReconnected!()
                self.tagsDelegate?.onReconnected!()
        })
        
        self.storageRef!.onReconnecting({ (storageRef) -> Void in
                currentSearchMonth = nil
                scrollLimit = limit
                lastTimestamp = nil
                
                isConnected = false
                self.contentsDelegate?.onReconnecting!()
                self.tagsDelegate?.onReconnecting!()
        })
    }
    
    func removeListeners(){
        self.storageRef!.onReconnected(nil)
        self.storageRef!.onReconnecting(nil)
    }
    
}


var token:String?
var isConnected:Bool = false
let sem = dispatch_semaphore_create(1)

class SM: NSObject {
    
    var storageRef:StorageRef?
    var tableRef:TableRef?
    var data:NSMutableArray?
    var dataIndex:NSMutableDictionary?
    var delegate:SMProtocol?
    var tableName:String?
    var onDiskData:NSMutableDictionary?
    var filters:NSMutableDictionary?
    var booted:Bool?
    var bootedMenu:Bool?
    var processing:Bool?
    var lastCount:Int?
    
    init(tableName:String, storageRef:StorageRef?)
    {
        super.init()
        self.tableName = tableName
        self.data = NSMutableArray()
        self.dataIndex = NSMutableDictionary()
        self.filters = NSMutableDictionary()
        self.booted = false
        self.bootedMenu = false
        self.lastCount = 1
        self.processing = false
        self.storageRef = storageRef
        
        self.tableRef = self.storageRef?.table(self.tableName)
        self.onDiskData = contentsOnDiskData
    }
    
    
    func appendFilter(filter:String, field:String)
    {
        self.tableRef?.equalsString(field, value: filter)
        self.filters?.setObject(field, forKey: filter)
    }
    
    func appendFilterLesser(filter:NSString, field:String)
    {
        self.tableRef?.lesserThanString(field, value:filter as String)
        self.filters?.setObject(field, forKey: filter)
    }
    
    func resetFilter()
    {
        self.tableRef = self.storageRef?.table(self.tableName)
        self.processing = false
        self.filters = NSMutableDictionary()
    }
    
    func reset()
    {
        self.data = NSMutableArray()
        self.dataIndex = NSMutableDictionary()
        self.filters = NSMutableDictionary()
        self.booted = false
        self.bootedMenu = false
        self.lastCount = 1
        self.processing = false
    }
        
    func checkTimestamp(item:DataObject)
    {
        let last:String? = NSUserDefaults.standardUserDefaults().objectForKey("lastTime") as? String
        
        if last == nil
        {
            NSUserDefaults.standardUserDefaults().setObject(item.timestamp, forKey: "lastTime")
            NSUserDefaults.standardUserDefaults().synchronize()
            return
        }
        
        let first:Double = item.timestamp!.doubleValue
        let second:Double = NSString(string: last!).doubleValue
        
        if (first > second)
        {
            NSUserDefaults.standardUserDefaults().setObject(item.timestamp, forKey: "lastTime")
            NSUserDefaults.standardUserDefaults().synchronize()
            item.isNew = true
        }
        
    }
    
    func getData(){
        if self.data == nil
        {
            self.data = NSMutableArray()
            self.dataIndex = NSMutableDictionary()
        }
        
        self.processing = true
        self.lastCount = 1
        NSNotificationCenter.defaultCenter().postNotificationName("startLoad", object: nil)
        
        self.tableRef!.limit(Int32(limit))
        self.tableRef?.desc().getItems({ (itemSnapshot) -> Void in
            
            if itemSnapshot != nil
            {
                let val:NSDictionary = itemSnapshot.val() as NSDictionary
                let item:DataObject = DataObject.loadDataObjectFromDictionary(val)
                
                item.isOffline = false
                self.data!.addObject(item)
                if val.objectForKey("IMG") != nil
                {
                    let img:String = val.objectForKey("IMG") as! String
                    item.imageURL = img
                    item.imageLoader = ImageLoader(item: item, img: img)
                }
                
                self.setContent(item)
                self.lastCount!++
            }else
            {
                DataObject.resetContentsOnDisk()
                self.processing = false
                self.delegate?.didReceivedData!(self.data!)
                NSNotificationCenter.defaultCenter().postNotificationName("endLoad", object: nil)
            }
            
            }, error: { (error) -> Void in
                self.processing = false
                self.setOffLineContents()
                NSNotificationCenter.defaultCenter().postNotificationName("endLoad", object: nil)
        })
        
        if self.booted! == false
        {
            self.tableRef?.on(StorageEventType.UPDATE, callback: { (itemSnapshot) -> Void in
                let val:NSDictionary = itemSnapshot.val() as NSDictionary
                let item:DataObject = DataObject.loadDataObjectFromDictionary(val)
                item.isOffline = false
                self.data!.addObject(item)
                self.delegate?.didReceivedItem!(item)
            })
            
            self.tableRef?.on(StorageEventType.DELETE, callback: { (itemSnapshot) -> Void in
                let val:NSDictionary = itemSnapshot.val() as NSDictionary
                self.delegate?.didDeleteItem!(DataObject.loadDataObjectFromDictionary(val))
            })
            
            self.booted = true
        }
    }
    
    func disableListeners(){
        self.tableRef?.off(StorageEventType.UPDATE)
        self.tableRef?.off(StorageEventType.DELETE)
    }
    
    
    func getMenu(){
        if (self.processing == true)
        {
            return
        }
        
        self.processing = true
        self.data = NSMutableArray()
        self.dataIndex = NSMutableDictionary()
        
        self.tableRef?.getItems({ (itemSnapshot) -> Void in
            if itemSnapshot != nil
            {
                let val:NSDictionary = itemSnapshot.val() as NSDictionary
                let item:DataObject = DataObject.loadDataObjectFromDictionary(val)
                item.isOffline = false
                self.data?.addObject(item)
                menuOnDiskData.setObject("1", forKey: "\(item.type!)-\(item.tag!).item")
                self.setContent(item)
                
            }else
            {
                DataObject.resetContentsOnDisk()
                DataObject.writeMenuOndisk()
                self.delegate?.didReceivedData!(self.data!)
                self.processing = false
            }
            
            }, error: { (error) -> Void in
                self.processing = false
                self.setOffLineContents()
        })
        
        if self.bootedMenu! == false
        {
            self.tableRef?.on(StorageEventType.UPDATE, callback: { (itemSnapshot) -> Void in
                let val:NSDictionary = itemSnapshot.val() as NSDictionary
                self.delegate?.didReceivedItem!(DataObject.loadDataObjectFromDictionary(val))
            })
            
            self.tableRef?.on(StorageEventType.DELETE, callback: { (itemSnapshot) -> Void in
                let val:NSDictionary = itemSnapshot.val() as NSDictionary
                self.delegate?.didDeleteItem!(DataObject.loadDataObjectFromDictionary(val))
            })
            
            self.bootedMenu = true
        }
    }
    
    
    func setOffLineContents(){
        
        if self.tableName == TABCONTENTS
        {
            self.loadOffLineData()
        }
        
        if self.tableName == TABTAGS
        {
            self.loadOffLineMenu()
        }
    }
    
    
    func setContent(item:DataObject!)
    {
        if item.type == nil || item.timestamp == nil
        {
            return
        }
        
        if item.type != nil && item.timestamp != nil
        {
            if item!.storeOnDisk() == true{
                let onDisk:NSMutableDictionary = contentsOnDiskData
                onDisk.setObject("1", forKey: "\(item!.type!)-\(item!.timestamp!).item")
                DataObject.writeContentOndisk()
            }
            self.dataIndex?.setObject(item, forKey: "\(item.type!)-\(item.timestamp!)")
            self.checkTimestamp(item)
        }
    }
    
    
    func loadOffLineMenu(){
        
        if (self.processing == true)
        {
            return
        }
        
        self.processing = true
        
        self.data = NSMutableArray()
        self.dataIndex = NSMutableDictionary()
        let contents = DataObject.MenuOnDisk()
        
        if contents == nil
        {
            return
        }
        
        for type in contents!.allKeys
        {
            let pptype:NSString! = type as! NSString
            let parts:NSArray! = pptype.componentsSeparatedByString("-")
            if parts == nil || parts.count < 2{
                return
            }
            let pType:String! = parts.objectAtIndex(0) as! String
            let pTag:String! = (parts.objectAtIndex(1).componentsSeparatedByString(".") as NSArray).objectAtIndex(0) as! String
            
            let obj:DataObject? = DataObject()
            obj?.type = pType
            obj?.tag = pTag

            if obj != nil{
                obj!.isOffline = true
                self.data?.addObject(obj!)
                self.dataIndex?.setObject(obj!, forKey: "\(obj!.type!)-\(obj!.tag!)")
            }
        }
        self.delegate?.didReceivedData!(self.data!)
        menuOnDiskData = NSMutableDictionary()
        self.processing = false
    }
    
    
    func loadOffLineData(){
        
        if (self.processing == true)
        {
            return
        }
        
        self.processing = true
        
        self.data = NSMutableArray()
        self.dataIndex = NSMutableDictionary()
        let contents = DataObject.contentsOnDisk()
        
        if contents == nil
        {
            return
        }
        
        for type in contents!.allKeys
        {
            let pptype:NSString! = type as! NSString
            let parts:NSArray! = pptype.componentsSeparatedByString("-")
            if parts == nil || parts.count < 2{
                return
            }
            let ptype:String! = parts.objectAtIndex(0) as! String
            let times:String! = (parts.objectAtIndex(1).componentsSeparatedByString(".") as NSArray).objectAtIndex(0) as! String
            
            let obj:DataObject? = DataObject.getFromDiskWithType(ptype!, timestamp: times!)
            
            if obj != nil{
                obj!.isOffline = true
                obj!.image = NSData(contentsOfFile: "\(DataObject.applicationDocumentsDirectory())/\(obj!.type!)-\(obj!.timestamp!).data")
                if obj!.image == nil
                {
                    obj!.image = defaultImage
                }

                self.data?.addObject(obj!)
                self.dataIndex?.setObject(obj!, forKey: "\(obj!.type!)-\(obj!.timestamp!)")                
            }
        }
        
        self.delegate?.didReceivedData!(Utils.orderTopics(self.data!))
        self.processing = false
    }
}






















